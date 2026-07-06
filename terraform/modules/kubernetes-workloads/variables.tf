variable "kubernetes_auth_backends" {
  description = "Kubernetes auth backends keyed by catalog auth key."
  type = map(object({
    mount                  = string
    display_name           = string
    description            = string
    kubernetes_host        = string
    disable_local_ca_jwt   = bool
    disable_iss_validation = bool
    issuer                 = optional(string)
    kubernetes_ca_cert     = optional(string)
    token_reviewer_jwt     = optional(string)
  }))
}

variable "workloads" {
  description = "Kubernetes workload bindings keyed by workload role name."
  type = map(object({
    auth_key              = string
    display_name          = string
    role_name             = string
    policy_name           = string
    namespaces            = list(string)
    service_accounts      = list(string)
    token_ttl_seconds     = number
    token_max_ttl_seconds = number
    read_secret_paths = list(object({
      mount_path = string
      path       = string
    }))
  }))
}
