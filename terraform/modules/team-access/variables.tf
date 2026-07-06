variable "teams" {
  description = "Normalized role catalog entries keyed by role slug."
  type        = any
}

variable "team_policy_bindings" {
  description = "Policy bindings keyed by role slug."
  type = map(object({
    team_slug   = string
    policy_name = string
    metadata_list_paths = list(object({
      mount_path = string
      path       = string
    }))
    read_secret_paths = list(object({
      mount_path = string
      path       = string
    }))
    write_secret_paths = list(object({
      mount_path = string
      path       = string
    }))
  }))
}

variable "team_login_token_ttl_seconds" {
  description = "Initial TTL, in seconds, for OIDC login tokens."
  type        = number
}

variable "team_login_token_max_ttl_seconds" {
  description = "Maximum TTL, in seconds, for OIDC login tokens."
  type        = number
}

variable "team_child_token_ttl_seconds" {
  description = "Initial TTL, in seconds, for child tokens created by team users."
  type        = number
}

variable "team_child_token_max_ttl_seconds" {
  description = "Maximum TTL, in seconds, for child tokens created by team users."
  type        = number
}

variable "auth0_oidc_enabled" {
  description = "Enable Auth0 OIDC auth backend and identity group aliases."
  type        = bool
  default     = false
}

variable "auth_method_accessors" {
  description = "Additional Vault auth method mount accessors keyed by auth source name for role auth aliases."
  type        = map(string)
  default     = {}
}

variable "auth0_oidc_mount_path" {
  description = "Vault auth mount path for Auth0 OIDC."
  type        = string
  default     = "oidc"
}

variable "auth0_oidc_discovery_url" {
  description = "Auth0 OIDC discovery URL."
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
  description = "Auth0 custom claim containing Vault role names."
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
  default     = []
}

variable "auth0_oidc_scopes" {
  description = "OIDC scopes requested by Vault."
  type        = list(string)
  default     = ["openid", "profile", "email"]
}
