# Lab 4: headers (15 min)

Edit the `edge` VirtualService (lab 2) to:

1. Add response headers `strict-transport-security` and `x-content-type-options: nosniff`.
2. Remove the response header `x-envoy-upstream-service-time`.
3. Set request header `x-workshop-name: <your name>` and remove request header `x-debug` on the way to the service.

Test: `curl -si -H 'Host: edge.workshop.example.com' -H 'x-debug: 1' http://$GW_IP/` (needs the lab 3 allow rule, from the VM). The echo body shows the request headers the service received.

Checkpoint: responses carry the new security headers and no `x-envoy-upstream-service-time`.
