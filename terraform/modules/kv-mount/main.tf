resource "vault_mount" "this" {
  path               = var.kv_mount
  type               = "kv"
  description        = var.description
  listing_visibility = var.listing_visibility

  options = {
    version = "2"
  }
}
