module "team_access" {
  source = "../team-access"

  teams                            = local.roles
  team_policy_bindings             = local.role_policy_bindings
  team_login_token_ttl_seconds     = var.team_login_token_ttl_seconds
  team_login_token_max_ttl_seconds = var.team_login_token_max_ttl_seconds
  team_child_token_ttl_seconds     = var.team_child_token_ttl_seconds
  team_child_token_max_ttl_seconds = var.team_child_token_max_ttl_seconds
  auth0_oidc_enabled               = var.auth0_oidc_enabled
  auth0_oidc_mount_path            = var.auth0_oidc_mount_path
  auth0_oidc_discovery_url         = var.auth0_oidc_discovery_url
  auth0_oidc_client_id             = var.auth0_oidc_client_id
  auth0_oidc_client_secret         = var.auth0_oidc_client_secret
  auth0_oidc_roles_claim           = var.auth0_oidc_roles_claim
  auth0_oidc_access_claim          = var.auth0_oidc_access_claim
  auth0_oidc_allowed_redirect_uris = var.auth0_oidc_allowed_redirect_uris
  auth0_oidc_scopes                = var.auth0_oidc_scopes

  depends_on = [module.kv_mounts]
}

module "kubernetes_workloads" {
  source = "../kubernetes-workloads"

  kubernetes_auth_backends = local.kubernetes_auth_backends
  workloads                = local.workloads

  depends_on = [module.kv_mounts]
}
