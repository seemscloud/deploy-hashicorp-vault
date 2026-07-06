output "kubernetes_auth_mounts" {
  description = "Vault Kubernetes auth paths keyed by catalog auth key."
  value = {
    for auth_key, backend in vault_auth_backend.kubernetes : auth_key => "auth/${backend.path}"
  }
}

output "kubernetes_auth_display_names" {
  description = "Human-readable Kubernetes auth mount names keyed by catalog auth key."
  value = {
    for auth_key, backend in var.kubernetes_auth_backends : auth_key => backend.display_name
  }
}

output "workload_policy_names" {
  description = "Vault policy names generated for Kubernetes workloads."
  value = {
    for workload_key, policy in vault_policy.workload : workload_key => policy.name
  }
}

output "workload_display_names" {
  description = "Human-readable workload names keyed by workload role name."
  value = {
    for workload_key, workload in var.workloads : workload_key => workload.display_name
  }
}

output "workload_role_names" {
  description = "Vault Kubernetes auth role names generated for workloads."
  value = {
    for workload_key, role in vault_kubernetes_auth_backend_role.workload : workload_key => role.role_name
  }
}

output "workload_pod_annotations" {
  description = "Minimal Vault Agent Injector annotations keyed by workload."
  value = {
    for workload_key, workload in var.workloads : workload_key => {
      "vault.hashicorp.com/agent-inject" = "true"
      "vault.hashicorp.com/auth-path"    = "auth/${var.kubernetes_auth_backends[workload.auth_key].mount}"
      "vault.hashicorp.com/role"         = vault_kubernetes_auth_backend_role.workload[workload_key].role_name
    }
  }
}
