#!/usr/bin/env bash
# Starts the workshop VMs that the daily auto-shutdown switched off, and shows their state and IPs.
# Run from your own machine (instructor), after `az login`. The VMs keep their static public IPs.
#
#   scripts/start-vms.sh                  start every workshop VM
#   scripts/start-vms.sh attendee-01      start only that attendee's VM
#   scripts/start-vms.sh --status         only show state and IP, start nothing
set -euo pipefail

RG="${RG:-rg-istio-ws-vms}"

if [[ "${1:-}" == "--status" ]]; then
  az vm list -g "$RG" -d --query "[].{name:name, state:powerState, ip:publicIps}" -o table
  exit 0
fi

if [[ $# -ge 1 ]]; then
  names=()
  for a in "$@"; do names+=("vm-istio-ws-$a"); done
  az vm start -g "$RG" --names "${names[@]}"
else
  ids="$(az vm list -g "$RG" --query "[].id" -o tsv)"
  [[ -n "$ids" ]] || { echo "No VMs found in $RG" >&2; exit 1; }
  # shellcheck disable=SC2086
  az vm start --ids $ids
fi

az vm list -g "$RG" -d --query "[].{name:name, state:powerState, ip:publicIps}" -o table
