# Stack 2: Istio, gateway, addons, sample apps

**Run by each attendee, on their workshop VM, after stack 1.** Installs upstream Istio on your cluster with Helm, then Kiali, Prometheus, the namespaces, the sample apps and the mock core API.

## What it installs

- Helm releases at `istio_version` (default 1.32.0): `base`, `istiod` and `gateway` (as `istio-ingress`, a public LoadBalancer with `externalTrafficPolicy: Local`) in `istio-system`.
- Kiali and Prometheus from the Istio sample addons for the matching release branch (`kubectl apply`).
- Namespace `apps` (labelled `istio-injection=enabled`) and `external` (no injection).
- Certificates and secrets from `scripts/certificates.sh` (uses `openssl` and `kubectl`).
- The services in `labs/apps/`: `edge`, `identity`, `portservice`, `onboarding`, `tls-backend`, `client`, and the mock `core-api` in `external`.

## Prerequisites

- Stack 1 applied (its `terraform.tfstate` is read through `terraform_remote_state`).
- `kubectl` pointing at your cluster: `eval "$(tofu -chdir=../stack-1-cluster output -raw get_credentials)"`. The `kubectl apply` steps use that kubeconfig, and the Helm and Kubernetes providers use the credentials from stack 1's state.

## Use

```bash
cd ~/istio-workshop/stack-2-mesh
tofu init
tofu apply
```

## Inputs

| Variable | Default | Notes |
| --- | --- | --- |
| `istio_version` | `1.32.0` | Exported as `TF_VAR_istio_version`. Must match `istioctl`, the docs and the sample manifests |
| `workshop_domain` | `workshop.example.com` | Fake domain for Host headers |

## Reset your labs

Destroying and re-applying this stack returns the mesh and sample apps to a clean state without recreating the cluster:

```bash
tofu destroy && tofu apply
```
