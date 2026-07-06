variable "vault_addr" {
  description = "Vault API address used by the provider and generated test scripts."
  type        = string
  default     = "https://vault.psem.io"
}

variable "roots_file" {
  description = "Path to the YAML KV roots catalog, relative to the terraform module directory."
  type        = string
  default     = "catalog/kv-roots.yaml"
}

variable "roles_file" {
  description = "Path to the YAML role grants catalog, relative to the terraform module directory."
  type        = string
  default     = "catalog/roles.yaml"
}

variable "example_secrets_file" {
  description = "Path to the YAML example secrets catalog, relative to the terraform module directory."
  type        = string
  default     = "catalog/kv-example-secrets.yaml"
}

variable "workloads_file" {
  description = "Path to the YAML Kubernetes workloads catalog, relative to the terraform module directory."
  type        = string
  default     = "catalog/workloads.yaml"
}

variable "team_login_token_ttl_seconds" {
  description = "Initial TTL, in seconds, for OIDC login tokens."
  type        = number
  default     = 28800
}

variable "team_login_token_max_ttl_seconds" {
  description = "Maximum TTL, in seconds, for OIDC login tokens."
  type        = number
  default     = 43200
}

variable "team_child_token_ttl_seconds" {
  description = "Initial TTL, in seconds, for child tokens created by team users."
  type        = number
  default     = 28800
}

variable "team_child_token_max_ttl_seconds" {
  description = "Maximum TTL, in seconds, for child tokens created by team users."
  type        = number
  default     = 86400
}

variable "auth0_oidc_enabled" {
  description = "Enable Auth0 OIDC auth backend and identity group aliases."
  type        = bool
  default     = false
}

variable "auth0_oidc_mount_path" {
  description = "Vault auth mount path for Auth0 OIDC."
  type        = string
  default     = "oidc"
}

variable "auth0_oidc_discovery_url" {
  description = "Auth0 OIDC discovery URL, for example https://tenant.us.auth0.com/."
  type        = string
  default     = null
  sensitive   = true
}

variable "auth0_oidc_client_id" {
  description = "Auth0 OIDC client ID."
  type        = string
  default     = null
  sensitive   = true
}

variable "auth0_oidc_client_secret" {
  description = "Auth0 OIDC client secret."
  type        = string
  default     = null
  sensitive   = true
}

variable "auth0_oidc_roles_claim" {
  description = "Auth0 custom claim containing Vault team role names."
  type        = string
  default     = "https://vault.psem.io/roles"
}

variable "auth0_oidc_access_claim" {
  description = "Auth0 custom claim that must be true for Vault OIDC access."
  type        = string
  default     = "https://vault.psem.io/vault_access"
}

variable "auth0_oidc_allowed_redirect_uris" {
  description = "Allowed redirect URIs for Vault OIDC login."
  type        = list(string)
  default = [
    "https://vault.psem.io/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
}

variable "auth0_oidc_scopes" {
  description = "OIDC scopes requested by Vault."
  type        = list(string)
  default     = ["openid", "profile", "email"]
}
