output "policy_names" {
  description = "Data policy names keyed by role slug."
  value = {
    for team_slug, policy in vault_policy.team_data : team_slug => policy.name
  }
}

output "auth0_oidc" {
  description = "Auth0 OIDC Vault login metadata."
  value = var.auth0_oidc_enabled ? {
    auth_path  = "auth/${vault_jwt_auth_backend.auth0[0].path}"
    role_name  = vault_jwt_auth_backend_role.auth0[0].role_name
    login_path = "ui/vault/auth/${vault_jwt_auth_backend.auth0[0].path}/oidc/callback"
    role_auth_aliases = {
      for group_key, auth_group in local.auth_groups : auth_group.team_slug => auth_group.aliases
      if auth_group.auth_source == "auth0"
    }
  } : null
}

output "identity_group_names" {
  description = "Vault external identity group names keyed by role slug and auth source."
  value = {
    for group_key, group in vault_identity_group.auth_group : group_key => group.name
  }
}
