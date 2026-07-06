resource "vault_kv_secret_v2" "example_secret" {
  for_each = var.example_secrets

  mount     = each.value.mount
  name      = each.value.name
  data_json = jsonencode(each.value.data)

  delete_all_versions = true
}
