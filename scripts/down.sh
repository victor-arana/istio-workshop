#!/usr/bin/env bash
# Run on the workshop VM. Destroys the mesh, then YOUR cluster and resource group in your
# subscription. Do this BEFORE the instructor destroys the VMs: the state lives on the VM, and
# the cluster keeps costing you money until it is gone.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"

tofu -chdir="$ROOT/stack-2-mesh" destroy -auto-approve -input=false || true
tofu -chdir="$ROOT/stack-1-cluster" destroy -auto-approve -input=false

echo
echo "Check nothing is left: az group list --tag purpose=istio-workshop -o table"
echo "Then sign out so your credentials don't stay on this VM: az logout"
