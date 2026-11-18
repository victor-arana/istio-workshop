#!/usr/bin/env bash
# Puts outboundTrafficPolicy back to ALLOW_ANY after lab 7 (run on the workshop VM, or with KUBECONFIG set).
set -euo pipefail
VERSION="${ISTIO_VERSION:-1.32.0}"
helm repo add istio https://istio-release.storage.googleapis.com/charts >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade istiod istio/istiod -n istio-system --version "$VERSION" \
  --reuse-values --set meshConfig.outboundTrafficPolicy.mode=ALLOW_ANY
kubectl -n istio-system rollout status deploy/istiod
echo "Egress restored. Restart workloads in apps to pick it up immediately: kubectl -n apps rollout restart deploy"
