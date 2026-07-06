# deploy-hashicorp-vault

## Purpose

This repository stores deployment configuration for HashiCorp Vault on Kubernetes using the official `hashicorp/vault` Helm chart from `https://helm.releases.hashicorp.com`.

## Structure

`chart/values.yaml` contains local Helm values for the Vault deployment. Upstream chart defaults should be inspected from a downloaded copy of the official chart, preferably under `/tmp`, rather than vendored into this repository unless explicitly requested.

`scripts/deploy.sh` runs `helm upgrade --install` for the official `hashicorp/vault` chart using `chart/values.yaml`.

Vault ingress is configured in `chart/values.yaml` for host `vault.psem.io` through ingress class `nginx-internal`, with TLS intended to be issued by cert-manager cluster issuer `cloudflare`.

Vault pod anti-affinity is intentionally disabled in `chart/values.yaml` so the test-sized cluster can schedule the deployment without requiring every replica to land on a different node.

`scripts/deploy.sh` disables Helm server-side apply with `--server-side=false` because the Vault Agent Injector updates the webhook `caBundle` dynamically through the `vault-k8s` field manager.

Enabled Vault components should define resource requests only, with no Kubernetes resource limits, using `cpu: 50m` and `memory: 128Mi` unless the user asks otherwise.

Fresh Vault deployments use manual Shamir bootstrap for development with `key-shares=1` and `key-threshold=1`. The generated unseal key and root token are stored locally in ignored root file `creds.txt`; it is a runtime secret file, must stay mode `600`, and must not be committed to this repository.

`terraform/` contains Vault OSS tenant bootstrap code driven by split YAML catalogs. Keep the Terraform root intentionally thin: `terraform/main.tf` should be the only root `.tf` file, acting as the provider/variable/output wrapper and calling `terraform/modules/vault-bootstrap`. Put reusable or bulky implementation below `terraform/modules/`, not in the Terraform root. `terraform/catalog/kv-roots.yaml` stores real KV v2 mount definitions and a nested `roots.<mount>.paths` tree whose keys are Vault path segments for intended browseable parent paths; `vault-bootstrap` normalizes that tree into flattened root paths. `terraform/catalog/roles.yaml` stores Vault roles, auth-source-specific external identity groups, auth aliases, and full-prefix grants such as `kv/lpp/gcp/services/service-aaa`; `terraform/catalog/kv-example-secrets.yaml` stores only example secret values to create; `terraform/catalog/workloads.yaml` stores Kubernetes auth mounts and app workload bindings. Access is generated only from `roles.yaml` for humans and `workloads.yaml` for applications; do not add test-only forbidden-service lists, secret values, root expansion rules, descriptions, or `_meta` marker definitions to role grants. `vault-bootstrap` decodes and normalizes these YAML files, while lower modules own specific resources: `kv-mount` owns KV v2 mounts, `kv-paths` owns only example KV entries and deletes all KV versions for removed examples, `team-access` owns human/Auth0 access, and `kubernetes-workloads` owns Kubernetes auth backends, workload policies, and workload auth roles.

In `terraform/catalog/roles.yaml`, each `roles.<role>.grants` key is a full user-facing Vault prefix and is the source of truth for human access only; values may set `access: read` or `access: write`. A write grant on `kv/lpp/gcp/services/service-aaa` intentionally allows the role to create, update, delete, and list anything below that service prefix, such as `prod/db`, `prod/api`, `test/db`, and `test/api`, without listing every child path in YAML. Auth mappings must use `auth_groups.<source>.name` for the UI-friendly Vault group name and `auth_groups.<source>.aliases` for exact auth-provider group or role values, for example `Auth0 / Vault - Team Alpha` with alias `Alpha`; aliases are case-sensitive and must exactly match the auth provider claim. Do not create secrets or store secret data in `roles.yaml`; example values belong in `terraform/catalog/kv-example-secrets.yaml`, grouped by service prefix with `paths[].path` for relative child secrets and `paths[].data` for dummy values.

Human roles may receive `list` on shared parent metadata paths such as `kv/metadata`, `kv/metadata/lpp/gcp`, and `kv/metadata/lpp/gcp/services` so the Vault UI can browse the tree and show sibling service directories. They must not receive `list` or `read` on an ungranted service root such as `kv/metadata/lpp/gcp/services/service-bbb`, so entering a foreign service directory returns permission denied. Terraform state contains dummy secret values and references to sensitive inputs, so state files are ignored and must not be committed.

Normal human access is Auth0 OIDC, and the built-in token auth method remains available only as break-glass/root-token access. Terraform must not create or tune `userpass/`; `terraform/team-users.auto.tfvars` and team userpass passwords are not part of the current model. Tune only `oidc/` and `token/` with `listing_visibility = "unauth"` so the unauthenticated Vault UI sees those auth mounts. `scripts/vault.sh` is a token-based dev verifier: it uses `VAULT_TOKEN` when provided, or the ignored local `creds.txt` root token only to mint a short-lived team-policy test token.

Auth0 OIDC is controlled by ignored local tfvars such as `terraform/auth0.auto.tfvars` and is the intended human login path. When enabled, Vault mounts OIDC at `auth/oidc`, uses one Vault OIDC role named `auth0` as `default_role`, and users should leave the Vault UI `Role` field blank. Vault reads human role names from the `https://vault.psem.io/roles` claim, requires `https://vault.psem.io/vault_access = "true"`, and maps Auth0 role names to Auth0-specific Vault external identity groups through each role's `auth_groups.auth0.aliases` values in `roles.yaml`. Additional auth methods should get their own `auth_groups.<source>` entries and use `auth_method_accessors` keyed by the same source name.

Application secrets live under `kv/lpp/<platform>/services/<service>/<env>/<secret>`. Future Kubernetes auth work should map `cluster + namespace + ServiceAccount` to application service policies that read the same service prefixes, while Auth0 remains for human secret management.

Kubernetes workload access is configured in `terraform/catalog/workloads.yaml`. Each Kubernetes auth mount represents one cluster/trust domain and should use a structural path like `k8s/<provider>/<account-or-project>/<region>/<cluster>`, for example `k8s/gke/prod-common-apps/europe-west1/karakoram`; do not encode cluster names into workload roles. Workload keys and Vault role names should be stable technical slugs such as `prod-service-aaa`, while optional `display_name` values such as `Prod / Service AAA` are for humans and outputs. Pods must use Vault Agent Injector annotations with `vault.hashicorp.com/role` set to a workload role name and, for non-default mounts such as the generated `auth/k8s/...` path, `vault.hashicorp.com/auth-path` set to the generated auth path. Pods and users must not supply policy names directly; Vault maps the Kubernetes service account and namespace to the workload policy.

## Execution Model

Use read-only inspection by default for Kubernetes and Helm work. Rendering, linting, diffing, and local chart inspection are allowed; installing, upgrading, deleting, restarting, or otherwise mutating Kubernetes resources requires explicit user confirmation. Running `scripts/deploy.sh` is a mutating deployment action.
