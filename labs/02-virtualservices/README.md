# Lab 2: VirtualServices (30 min)

Domain: `workshop.example.com`. Test with a Host header, no DNS: `curl -H 'Host: edge.workshop.example.com' http://$GW_IP/`.
The gateway is `istio-ingress` in `istio-system` (selector `istio: ingress`).

Start with `gateway.yaml`, then write the VirtualServices (answers in `solution/`).

1. Apply `gateway.yaml` (a Gateway for `*.workshop.example.com` on port 80).
2. Expose `edge` on `edge.workshop.example.com`.
3. Expose `identity` on `identity.workshop.example.com`. The Service is called `identity-service`, not `identity`.
4. Expose `portservice` on `port.workshop.example.com`. It listens on 8082.
5. Split `app.workshop.example.com` by prefix: `/onboarding` -> `onboarding`, everything else -> `edge`.

Checkpoint: each host returns its own service (look at the `hostname`/`os.hostname` field in the echo output), and each path prefix reaches the right service.
Check with `istioctl analyze` and `istioctl proxy-config routes deploy/istio-ingress -n istio-system`.
