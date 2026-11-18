# Lab 3: default-deny and authorization policies (35 min) [cloud]

1. Apply `deny-all.yaml`. An ALLOW policy with no rules allows nothing at the gateway, so every host now returns HTTP 403 (`RBAC: access denied`). Confirm with the curls from lab 2.
2. Open `edge.workshop.example.com` by **IP range**: allow requests from this VM (`$MY_IP`, a fixed public IP). Use `remoteIpBlocks` (reads `X-Forwarded-For`) or `ipBlocks` (peer address)? The gateway keeps the client IP (`externalTrafficPolicy: Local`); try both and see which works. `envsubst` fills `$MY_IP`.
3. Open `app.workshop.example.com` by **header value**: only requests with `x-workshop-token: made-up-token-123`.
4. Open `identity.workshop.example.com` **publicly**.

Checkpoint: a blocked request gets 403, and each allow rule opens exactly one host.
Hint: the policy's `to.operation.hosts` selects the host.

Note: a request from another network shows the 403 for `edge` too: use `curl -H 'X-Forwarded-For: 198.51.100.7' ...` to see how `remoteIpBlocks` reacts to a spoofed header, and discuss why the gateway's trusted-proxy setting matters.
