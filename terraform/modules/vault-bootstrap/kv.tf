module "kv_mounts" {
  for_each = local.kv_mounts

  source = "../kv-mount"

  kv_mount           = each.value.path
  description        = each.value.description
  listing_visibility = each.value.listing_visibility
}

module "kv_paths" {
  source = "../kv-paths"

  example_secrets = local.example_secrets

  depends_on = [module.kv_mounts]
}
