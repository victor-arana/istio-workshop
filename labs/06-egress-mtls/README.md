# Lab 6: ServiceEntry and mutual TLS (30 min)

The in-mesh `client` pod makes the calls: `kubectl -n apps exec deploy/client -c curl -- curl -s ...`.

Part A: an external host through a ServiceEntry
1. Register `example.com` (HTTP/80) with a ServiceEntry (`MESH_EXTERNAL`, `DNS`). Call it from `client`.
2. `istioctl proxy-config clusters deploy/client -n apps | grep example.com` shows it is now known to the mesh.

Part B: `core-api` with mutual TLS
1. `core-api` (namespace `external`, no sidecar) requires a client certificate. Call it directly with plain HTTP from `client`, then with `curl -k https://core-api.external.svc.cluster.local` and no certificate. Both fail.
2. Register `core-api.workshop.example.com` with a ServiceEntry that resolves to `core-api.external.svc.cluster.local:443`.
3. Add a DestinationRule with `tls.mode: MUTUAL` and `credentialName: core-api-client` (secret created by `scripts/certificates.sh`, in `apps`). The client then calls `http://core-api.workshop.example.com:80` and the sidecar originates mutual TLS.
4. Check the JSON reply shows `"verified":"SUCCESS"`; delete the DestinationRule and it fails.

Checkpoint: the call to `core-api` succeeds with the client certificate and fails without it.
