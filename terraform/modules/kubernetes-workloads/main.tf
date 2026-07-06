resource "vault_auth_backend" "kubernetes" {
  for_each = var.kubernetes_auth_backends

  type        = "kubernetes"
  path        = each.value.mount
  description = each.value.description
}

resource "vault_kubernetes_auth_backend_config" "this" {
  for_each = var.kubernetes_auth_backends

  backend                = vault_auth_backend.kubernetes[each.key].path
  kubernetes_host        = each.value.kubernetes_host
  disable_local_ca_jwt   = each.value.disable_local_ca_jwt
  disable_iss_validation = each.value.disable_iss_validation
  issuer                 = try(each.value.issuer, null)
  kubernetes_ca_cert     = try(each.value.kubernetes_ca_cert, null)
  token_reviewer_jwt     = try(each.value.token_reviewer_jwt, null)
}

resource "vault_policy" "workload" {
  for_each = var.workloads

  name = each.value.policy_name

  policy = templatefile("${path.module}/templates/workload-read-policy.hcl.tftpl", {
    read_secret_paths = each.value.read_secret_paths
  })
}

resource "vault_kubernetes_auth_backend_role" "workload" {
  for_each = var.workloads

  backend                          = vault_auth_backend.kubernetes[each.value.auth_key].path
  role_name                        = each.value.role_name
  bound_service_account_names      = each.value.service_accounts
  bound_service_account_namespaces = each.value.namespaces
  token_policies                   = [vault_policy.workload[each.key].name]
  token_ttl                        = each.value.token_ttl_seconds
  token_max_ttl                    = each.value.token_max_ttl_seconds
  token_type                       = "service"
}
