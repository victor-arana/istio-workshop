The sidecar is `istio-proxy`. `external` has no `istio-injection` label, so its pods get no sidecar.
If pods show 1/1: `kubectl -n apps rollout restart deploy`.
