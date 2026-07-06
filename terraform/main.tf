terraform {
  required_version = ">= 1.5.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0.0"
    }
  }
}

provider "vault" {
  address = var.vault_addr
}

variable "vault_addr" {
  description = "Vault API address used by the provider and generated test scripts."
  type        = string
  default     = "https://vault.psem.io"
}

variable "roots_file" {
  description = "Path to the YAML KV roots catalog, relative to the terraform directory."
  type        = string
  default     = "catalog/kv-roots.yaml"
}

variable "roles_file" {
  description = "Path to the YAML role grants catalog, relative to the terraform directory."
  type        = string
  default     = "catalog/roles.yaml"
}

variable "example_secrets_file" {
  description = "Path to the YAML example secrets catalog, relative to the terraform directory."
  type        = string
  default     = "catalog/kv-example-secrets.yaml"
}

variable "workloads_file" {
  description = "Path to the YAML Kubernetes workloads catalog, relative to the terraform directory."
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

module "vault_bootstrap" {
  source = "./modules/vault-bootstrap"

  vault_addr                       = var.vault_addr
  roots_file                       = "${path.module}/${var.roots_file}"
  roles_file                       = "${path.module}/${var.roles_file}"
  example_secrets_file             = "${path.module}/${var.example_secrets_file}"
  workloads_file                   = "${path.module}/${var.workloads_file}"
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
}

output "vault_addr" {
  description = "Vault API address used by this Terraform configuration."
  value       = module.vault_bootstrap.vault_addr
}

output "kv_mount_paths" {
  description = "KV v2 mount paths keyed by mount name."
  value       = module.vault_bootstrap.kv_mount_paths
}

output "root_paths" {
  description = "Flattened KV root paths decoded from terraform/catalog/kv-roots.yaml."
  value       = module.vault_bootstrap.root_paths
}

output "role_policy_names" {
  description = "Vault policy names generated for each role."
  value       = module.vault_bootstrap.role_policy_names
}

output "identity_group_names" {
  description = "Vault external identity group names keyed by role slug."
  value       = module.vault_bootstrap.identity_group_names
}

output "role_grant_prefixes" {
  description = "Full KV prefixes granted to each role."
  value       = module.vault_bootstrap.role_grant_prefixes
}

output "example_secret_paths" {
  description = "Example secret paths managed by Terraform. Do not use this for real production secret values."
  value       = module.vault_bootstrap.example_secret_paths
}

output "auth0_oidc" {
  description = "Auth0 OIDC Vault login metadata when enabled."
  value       = module.vault_bootstrap.auth0_oidc
}

output "kubernetes_auth_mounts" {
  description = "Vault Kubernetes auth paths keyed by catalog auth key."
  value       = module.vault_bootstrap.kubernetes_auth_mounts
}

output "kubernetes_auth_display_names" {
  description = "Human-readable Kubernetes auth mount names keyed by catalog auth key."
  value       = module.vault_bootstrap.kubernetes_auth_display_names
}

output "workload_policy_names" {
  description = "Vault policy names generated for Kubernetes workloads."
  value       = module.vault_bootstrap.workload_policy_names
}

output "workload_display_names" {
  description = "Human-readable Kubernetes workload names keyed by workload role name."
  value       = module.vault_bootstrap.workload_display_names
}

output "workload_role_names" {
  description = "Vault Kubernetes auth role names generated for workloads."
  value       = module.vault_bootstrap.workload_role_names
}

output "workload_pod_annotations" {
  description = "Minimal Vault Agent Injector annotations keyed by workload."
  value       = module.vault_bootstrap.workload_pod_annotations
}
