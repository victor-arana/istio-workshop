# Lab 8: telemetry (15 min)

1. Confirm `edge` has no access logs: send requests, `kubectl -n apps logs deploy/edge -c istio-proxy --tail=5`.
2. Apply `solution/access-logs-on.yaml` (a Telemetry resource scoped to `app: edge`). Send requests and read the lines.
3. Disable it (`solution/access-logs-off.yaml`: `disabled: true`) and confirm no new lines appear.

Checkpoint: with logging on, every request to the workload appears in `kubectl logs -c istio-proxy`, and with it off no new lines appear.
