# Sourced from ~/.bashrc on the workshop VM. Source it again if GW_IP is empty:
#   source ~/istio-workshop/labs/env.sh
case "$PS1" in "[sandbox "*) ;; *) PS1="[sandbox ${WORKSHOP_NAME:-?}] $PS1";; esac

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is not installed yet: see lab 0 (scripts/install-tools.sh)."
  export GW_IP=""
elif kubectl config current-context >/dev/null 2>&1; then
  echo "cluster: $(kubectl config current-context)  (expected aks-istio-ws-${WORKSHOP_NAME})"
  export GW_IP="$(kubectl -n istio-system get svc istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
else
  echo "No cluster yet: follow lab 0 to create yours."
  export GW_IP=""
fi
export MY_IP="$(curl -s --max-time 5 https://ifconfig.me || true)"   # this VM's public IP, for lab 3
echo "GW_IP=$GW_IP  MY_IP=$MY_IP"
