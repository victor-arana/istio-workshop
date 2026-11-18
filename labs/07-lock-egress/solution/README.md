The `envoy` provider writes logs to the proxy's stdout, which needs `meshConfig.accessLogFile=/dev/stdout` in 1.32 for the provider to emit lines in some versions;
OpenTofu leaves it unset on purpose, so logging is per workload via Telemetry. If no lines appear, check `istioctl proxy-config bootstrap`.

Allow-list ServiceEntries are in `../../06-egress-mtls/solution/`.
Locking down: see the helm command in the lab README.
