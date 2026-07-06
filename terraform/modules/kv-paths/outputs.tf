output "example_secret_paths" {
  description = "Full KV paths for example secrets managed by this module."
  value = {
    for key, secret in var.example_secrets : key => "${secret.mount}/${secret.name}"
  }
}
