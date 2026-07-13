| File | Method | Reload | Delivery | etcd | Security | Use |
| --- | --- | --- | --- | --- | --- | --- |
| `injector-init-file.yaml` | Injector init | No | File | No | 9/10 | Default static config |
| `injector-init-env.yaml` | Injector init | No | Env via `source` | No | 7/10 | Legacy env-only apps |
| `injector-sidecar-file.yaml` | Injector sidecar | Yes (1m) | File | No | 8/10 | Reloadable config |
| `agent-sidecar-file.yaml` | Vault Agent sidecar | Yes (1m) | File | No | 8/10 | Advanced Agent config |
| `client-cli.yaml` | Vault CLI | No | App memory/file | No | 5/10 | Debug only |
| `client-python-sdk.yaml` | Python `hvac` | App-defined | App memory | No | 8/10 | Dynamic secrets |
| `secrets-operator.yaml` | Vault Secrets Operator | Yes (1m) | K8s Secret | Yes | 6/10 | Only when K8s Secret is required |
