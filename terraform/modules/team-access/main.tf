locals {
  configured_auth_method_accessors = merge(
    var.auth_method_accessors,
    var.auth0_oidc_enabled ? {
      auth0 = vault_jwt_auth_backend.auth0[0].accessor
    } : {}
  )

  auth_groups = {
    for group in flatten([
      for team_slug, team in var.teams : [
        for auth_source, auth_group in try(team.auth_groups, {}) : {
          key         = "${team_slug}/${auth_source}"
          team_slug   = team_slug
          auth_source = auth_source
          name        = auth_group.name
          aliases     = auth_group.aliases
        }
        if contains(keys(local.configured_auth_method_accessors), auth_source) && length(auth_group.aliases) > 0
      ]
    ]) : group.key => group
  }

  identity_group_aliases = {
    for alias in flatten([
      for group_key, auth_group in local.auth_groups : [
        for alias_name in auth_group.aliases : {
          key         = "${group_key}/${alias_name}"
          group_key   = group_key
          team_slug   = auth_group.team_slug
          auth_source = auth_group.auth_source
          alias_name  = alias_name
        }
      ]
    ]) : alias.key => alias
  }
}

resource "vault_policy" "team_data" {
  for_each = var.team_policy_bindings

  name = each.value.policy_name

  policy = templatefile("${path.module}/templates/team-secrets-policy.hcl.tftpl", {
    metadata_list_paths = each.value.metadata_list_paths
    read_secret_paths   = each.value.read_secret_paths
    write_secret_paths  = each.value.write_secret_paths
  })
}

resource "vault_policy" "team_token_factory" {
  for_each = var.teams

  name = "${each.key}-token-factory"

  policy = templatefile("${path.module}/templates/team-token-factory-policy.hcl.tftpl", {
    token_role_name = each.value.token_role_name
  })
}

resource "vault_token_auth_backend_role" "team" {
  for_each = var.teams

  role_name = each.value.token_role_name

  allowed_policies = [
    vault_policy.team_data[each.key].name,
  ]

  renewable      = true
  token_num_uses = 0
  token_type     = "service"
}

resource "vault_jwt_auth_backend" "auth0" {
  count = var.auth0_oidc_enabled ? 1 : 0

  path                = var.auth0_oidc_mount_path
  type                = "oidc"
  oidc_discovery_url  = var.auth0_oidc_discovery_url
  oidc_client_id      = var.auth0_oidc_client_id
  oidc_client_secret  = var.auth0_oidc_client_secret
  default_role        = "auth0"
  description         = "Leave Role blank. Auth0 roles assign Vault team access."
}

resource "vault_generic_endpoint" "oidc_unauth_listing" {
  count = var.auth0_oidc_enabled ? 1 : 0

  path                 = "sys/auth/${vault_jwt_auth_backend.auth0[0].path}/tune"
  ignore_absent_fields = true
  disable_delete       = true

  data_json = jsonencode({
    description        = "Leave Role blank. Auth0 roles assign Vault team access."
    listing_visibility = "unauth"
  })
}

resource "vault_generic_endpoint" "token_unauth_listing" {
  path                 = "sys/auth/token/tune"
  ignore_absent_fields = true
  disable_delete       = true

  data_json = jsonencode({
    listing_visibility = "unauth"
  })
}

resource "vault_jwt_auth_backend_role" "auth0" {
  count = var.auth0_oidc_enabled ? 1 : 0

  backend               = vault_jwt_auth_backend.auth0[0].path
  role_name             = "auth0"
  role_type             = "oidc"
  user_claim            = "email"
  groups_claim          = var.auth0_oidc_roles_claim
  bound_audiences       = [var.auth0_oidc_client_id]
  allowed_redirect_uris = var.auth0_oidc_allowed_redirect_uris
  oidc_scopes           = var.auth0_oidc_scopes
  token_ttl             = var.team_login_token_ttl_seconds
  token_max_ttl         = var.team_login_token_max_ttl_seconds
  token_type            = "service"

  bound_claims = {
    (var.auth0_oidc_access_claim) = "true"
  }
}

resource "vault_identity_group" "auth_group" {
  for_each = local.auth_groups

  name = each.value.name
  type = "external"

  policies = [
    vault_policy.team_data[each.value.team_slug].name,
    vault_policy.team_token_factory[each.value.team_slug].name,
  ]

  metadata = {
    role        = each.value.team_slug
    auth_source = each.value.auth_source
  }
}

resource "vault_identity_group_alias" "auth_alias" {
  for_each = local.identity_group_aliases

  name           = each.value.alias_name
  mount_accessor = local.configured_auth_method_accessors[each.value.auth_source]
  canonical_id   = vault_identity_group.auth_group[each.value.group_key].id
}
