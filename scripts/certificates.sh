#!/usr/bin/env bash
# Generates a CA, a core-api server cert and a client cert, then creates the
# secrets the labs use. Uses KUBECONFIG from the environment (or the VM's default).
# Everything uses example.com names; nothing here is a real credential.
set -euo pipefail

DIR="${CERT_DIR:-$(cd "$(dirname "$0")/.." && pwd)/.certs/local}"
mkdir -p "$DIR"; cd "$DIR"

if [[ ! -f ca.crt ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj "/O=workshop/CN=workshop-ca" \
    -keyout ca.key -out ca.crt
  # server cert for core-api
  openssl req -newkey rsa:2048 -nodes -subj "/CN=core-api.workshop.example.com" \
    -keyout server.key -out server.csr
  printf 'subjectAltName=DNS:core-api.workshop.example.com,DNS:core-api.external.svc.cluster.local' > server.ext
  openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 \
    -extfile server.ext -out server.crt
  # client cert for the mesh
  openssl req -newkey rsa:2048 -nodes -subj "/CN=workshop-client" -keyout client.key -out client.csr
  openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 -out client.crt
  # tls-backend cert, for the passthrough lab
  openssl req -newkey rsa:2048 -nodes -subj "/CN=secure.workshop.example.com" \
    -keyout backend.key -out backend.csr
  printf 'subjectAltName=DNS:secure.workshop.example.com' > backend.ext
  openssl x509 -req -in backend.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 \
    -extfile backend.ext -out backend.crt
fi

apply() { kubectl "$@" --dry-run=client -o yaml | kubectl apply -f -; }

# core-api: server cert, key and the CA that must sign client certs
apply -n external create secret generic core-api-tls \
  --from-file=tls.crt=server.crt --from-file=tls.key=server.key --from-file=ca.crt=ca.crt
# client side, in apps, for DestinationRule credentialName (keys per Istio's generic secret format)
apply -n apps create secret generic core-api-client \
  --from-file=tls.crt=client.crt --from-file=tls.key=client.key --from-file=ca.crt=ca.crt
# a client cert not signed by anything core-api trusts is not needed: omit it to see the failure
# tls-backend serves its own certificate on 8443
apply -n apps create secret generic tls-backend-cert \
  --from-file=tls.crt=backend.crt --from-file=tls.key=backend.key
echo "Certificates ready in $DIR"
