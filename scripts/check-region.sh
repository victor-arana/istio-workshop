#!/usr/bin/env bash
# Checks whether a VM size is available to YOUR subscription in one or more regions, and shows
# the vCPU quota. Run it before choosing `location`/`vm_size` (workstation) or `aks_location`/
# `aks_vm_size` (attendees' clusters). Needs `az login`.
#
#   scripts/check-region.sh eastus2 westeurope              check Standard_B2s in those regions
#   SIZE=Standard_D2s_v5 scripts/check-region.sh westeurope  check another size
#   LIST=1 scripts/check-region.sh eastus2                   also list sizes you can actually create
#
# In the size table, "restrictions 0" means available. No row means the size isn't offered.
set -euo pipefail

SIZE="${SIZE:-Standard_B2s}"
[[ $# -ge 1 ]] || { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

for region in "$@"; do
  echo
  echo "=================== $region ==================="

  echo "--- $SIZE"
  out="$(az vm list-skus -l "$region" --resource-type virtualMachines --all \
    --query "[?name=='$SIZE'].{name:name, restrictions:length(restrictions)}" -o table)"
  if [[ -n "$out" ]]; then echo "$out"; else echo "not offered in $region"; fi

  echo "--- vCPU quota (name, current usage, limit)"
  az vm list-usage -l "$region" -o table | grep -iE "Name  |Total Regional vCPUs|Standard (BS|DSv5|Dsv5) Family" || true

  if [[ "${LIST:-}" == "1" ]]; then
    echo "--- usable 2-vCPU sizes: no restriction AND quota in the size's family (limit > 0)"
    usage="$(az vm list-usage -l "$region" --query "[].[name.value, limit]" -o tsv)"
    skus="$(az vm list-skus -l "$region" --resource-type virtualMachines --all \
      --query "[?length(restrictions)==\`0\` && capabilities[?name=='vCPUs' && value=='2']].[name, family]" -o tsv)"
    printf '%-24s %-34s %s\n' "SIZE" "FAMILY" "FAMILY_LIMIT"
    awk -F'\t' 'NR==FNR { lim[tolower($1)] = $2; next }
      { l = lim[tolower($2)]; if (l + 0 > 0) printf "%-24s %-34s %s\n", $1, $2, l }' \
      <(printf '%s\n' "$usage") <(printf '%s\n' "$skus") | sort
    echo "(Also keep within 'Total Regional vCPUs' above.)"
  fi
done
