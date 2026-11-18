# Self-study

Optional topics outside the 4-hour session. Check which API each istio.io task uses in 1.32 before adapting it.

| Topic | Notes |
| --- | --- |
| `routing/` | Request routing and traffic shifting by version on Bookinfo |
| `resilience/` | Timeouts, retries, fault injection, circuit breaking |
| `strict-mtls/` | `PeerAuthentication` STRICT, per namespace and per workload |
| `ambient/` | Ambient mode on Bookinfo (stable since 1.24) |
| `kind/` | Run the `[no tag]` labs locally, below |

Bookinfo: `kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.32/samples/bookinfo/platform/kube/bookinfo.yaml`

## kind

```bash
kind create cluster --name istio-ws
helm repo add istio https://istio-release.storage.googleapis.com/charts && helm repo update
helm install istio-base istio/base -n istio-system --create-namespace --version 1.32.0
helm install istiod istio/istiod -n istio-system --version 1.32.0 --wait
helm install istio-ingress istio/gateway -n istio-system --version 1.32.0
kubectl create ns apps && kubectl label ns apps istio-injection=enabled
kubectl create ns external
scripts/certificates.sh && kubectl apply -f labs/apps/
```

The gateway has no public IP on kind: `kubectl -n istio-system port-forward svc/istio-ingress 8080:80` and curl `localhost:8080` with the Host header. Labs tagged `[cloud]` (source IP) don't apply.
