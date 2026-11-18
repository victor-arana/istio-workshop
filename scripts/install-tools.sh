#!/usr/bin/env bash
# Installs the tools the workshop needs on the workshop VM (Ubuntu 24.04).
#   scripts/install-tools.sh           install whatever is missing
#   scripts/install-tools.sh --check   only report what is installed
#
# On the "minimal" VM an attendee runs this (or the same commands by hand, see lab 0).
# On the "preinstalled" VM, first boot runs it. Safe to run twice.
set -euo pipefail

ISTIO_VERSION="${ISTIO_VERSION:-1.32.0}"
TOOLS=(git curl jq openssl envsubst az kubectl helm tofu istioctl)
have() { command -v "$1" >/dev/null 2>&1; }

if [[ "${1:-}" == "--check" ]]; then
  missing=0
  for t in "${TOOLS[@]}"; do
    if have "$t"; then printf '%-10s ok\n' "$t"; else printf '%-10s MISSING\n' "$t"; missing=1; fi
  done
  exit $missing
fi

SUDO=""; [[ $EUID -ne 0 ]] && SUDO="sudo"

echo "==> base packages"
$SUDO apt-get update -y
$SUDO apt-get install -y git curl jq tmux unzip gettext-base openssl gnupg ca-certificates

echo "==> Azure CLI"
have az || curl -sL https://aka.ms/InstallAzureCLIDeb | $SUDO bash

echo "==> kubectl"
have kubectl || $SUDO az aks install-cli

echo "==> Helm"
have helm || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "==> OpenTofu"
if ! have tofu; then
  tmp="$(mktemp -d)"
  curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o "$tmp/install-opentofu.sh"
  chmod +x "$tmp/install-opentofu.sh"
  $SUDO "$tmp/install-opentofu.sh" --install-method deb
  rm -rf "$tmp"
fi

echo "==> istioctl $ISTIO_VERSION"
if ! have istioctl; then
  tmp="$(mktemp -d)"
  (cd "$tmp" && curl -L https://istio.io/downloadIstio | ISTIO_VERSION="$ISTIO_VERSION" sh -)
  $SUDO install "$tmp/istio-$ISTIO_VERSION/bin/istioctl" /usr/local/bin/istioctl
  rm -rf "$tmp"
fi

echo
"$0" --check
