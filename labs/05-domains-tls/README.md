# Lab 5: extra domains and TLS passthrough (25 min)

Part A: a second domain with its own Gateway
1. Create a Gateway `second-domain` for `shop.example.net` (port 80), and a VirtualService from it to `edge`.
2. Show that `Host: shop.example.net` works but only through its own Gateway: delete the Gateway and the host stops answering (allow it in lab 3's policy first).

Part B: TLS passthrough by SNI
1. Create a Gateway on port 443 with `tls.mode: PASSTHROUGH` for `secure.workshop.example.com`.
2. Create a VirtualService with a `tls` match on that SNI that routes to `tls-backend:8443`.
3. `curl -k --resolve secure.workshop.example.com:443:$GW_IP https://secure.workshop.example.com/` and check the certificate: `openssl s_client -connect $GW_IP:443 -servername secure.workshop.example.com </dev/null | openssl x509 -noout -subject` should show `CN=secure.workshop.example.com`, the backend's own certificate, not an Istio one.

Checkpoint: the second domain works only through its own Gateway, and passthrough reaches `tls-backend` with its own certificate.
