output "vault_addr" {
  description = "Vault API address used by this Terraform configuration."
  value       = var.vault_addr
}

output "kv_mount_paths" {
  description = "KV v2 mount paths keyed by mount name."
  value = {
    for mount_name, mount in module.kv_mounts : mount_name => mount.path
  }
}

output "root_paths" {
  description = "Flattened KV root paths decoded from the nested roots catalog."
  value = {
    for key, root_path in local.root_paths : key => root_path.full_path
  }
}

output "role_policy_names" {
  description = "Vault policy names generated for each role."
  value       = module.team_access.policy_names
}

output "identity_group_names" {
  description = "Vault external identity group names keyed by role slug."
  value       = module.team_access.identity_group_names
}

output "role_grant_prefixes" {
  description = "Full KV prefixes granted to each role."
  value = {
    for role_slug in keys(local.roles) : role_slug => [
      for grant in values(local.role_grants) : "${grant.mount_path}/${grant.path}"
      if grant.role_slug == role_slug
    ]
  }
}

output "example_secret_paths" {
  description = "Example secret paths managed by Terraform. Do not use this for real production secret values."
  value       = module.kv_paths.example_secret_paths
}

output "auth0_oidc" {
  description = "Auth0 OIDC Vault login metadata when enabled."
  value       = module.team_access.auth0_oidc
}

output "kubernetes_auth_mounts" {
  description = "Vault Kubernetes auth paths keyed by catalog auth key."
  value       = module.kubernetes_workloads.kubernetes_auth_mounts
}

output "kubernetes_auth_display_names" {
  description = "Human-readable Kubernetes auth mount names keyed by catalog auth key."
  value       = module.kubernetes_workloads.kubernetes_auth_display_names
}

output "workload_policy_names" {
  description = "Vault policy names generated for Kubernetes workloads."
  value       = module.kubernetes_workloads.workload_policy_names
}

output "workload_display_names" {
  description = "Human-readable Kubernetes workload names keyed by workload role name."
  value       = module.kubernetes_workloads.workload_display_names
}

output "workload_role_names" {
  description = "Vault Kubernetes auth role names generated for workloads."
  value       = module.kubernetes_workloads.workload_role_names
}

output "workload_pod_annotations" {
  description = "Minimal Vault Agent Injector annotations keyed by workload."
  value       = module.kubernetes_workloads.workload_pod_annotations
}
