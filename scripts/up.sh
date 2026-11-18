#!/usr/bin/env bash
# Run on the workshop VM, after `az login` (lab 0 step 1). Creates your AKS cluster in YOUR
# subscription (stack 1), fetches credentials, then installs the mesh and sample apps (stack 2).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

az account show >/dev/null 2>&1 || { echo "Not signed in. Run: az login --use-device-code" >&2; exit 1; }
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
echo "Subscription: $(az account show --query name -o tsv) ($ARM_SUBSCRIPTION_ID)"

echo "==> resource providers"
for p in Microsoft.ContainerService Microsoft.Compute Microsoft.Network Microsoft.Storage; do
  az provider register --namespace "$p" --wait
done

tofu -chdir="$ROOT/stack-1-cluster" init -input=false
tofu -chdir="$ROOT/stack-1-cluster" apply -auto-approve -input=false
eval "$(tofu -chdir="$ROOT/stack-1-cluster" output -raw get_credentials)"

tofu -chdir="$ROOT/stack-2-mesh" init -input=false
tofu -chdir="$ROOT/stack-2-mesh" apply -auto-approve -input=false
echo "Done. Run: source $ROOT/labs/env.sh"
