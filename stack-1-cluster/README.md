# Stack 1: your AKS cluster

**Run by each attendee, on their workshop VM, against their own Azure subscription.** Creates a resource group and one AKS cluster in the subscription you sign in to, and outputs the cluster's kubeconfig. Stack 2 (`../stack-2-mesh`) reads that output and installs Istio on top.

## How it authenticates

You sign in with your own account (`az login --use-device-code`, lab 0) and export `ARM_SUBSCRIPTION_ID`. OpenTofu's azurerm provider then uses your Azure CLI session. The instructor's VM has no Azure permissions of its own, and the instructor never sees your subscription, but your sign-in token is stored on the VM (`~/.azure`) until you run `az logout`.

## What it creates

| Resource | Name |
| --- | --- |
| Resource group | `rg-istio-ws-<attendee>` |
| AKS cluster (Free tier, system-assigned identity, one default node pool) | `aks-istio-ws-<attendee>` |

Tags: `purpose=istio-workshop`, `attendee`, `delete_after`.

## Prerequisites (in your subscription)

- You can create resource groups and AKS clusters there (Contributor or Owner).
- Resource providers registered: `Microsoft.ContainerService`, `Microsoft.Compute`, `Microsoft.Network`, `Microsoft.Storage` (lab 0 and `scripts/up.sh` register them; this needs Contributor on the subscription).
- vCPU quota in the chosen region: `node_count × vCPUs per node`. With the defaults, 3 × 2 = 6 vCPUs of `Standard_D2s_v5`.

## Inputs

All come from `TF_VAR_*` variables set on the VM, so `tofu apply` takes no arguments.

| Variable | Notes |
| --- | --- |
| `attendee` | Your attendee name |
| `location` | Region for your resource group and cluster |
| `kubernetes_version` | Pinned by the instructor |
| `vm_size` | Node size, default `Standard_D2s_v5` |
| `node_count` | Default `3` |
| `delete_after` | Tag value |

The subscription is not a variable: it is `ARM_SUBSCRIPTION_ID`.

## Use

```bash
az login --use-device-code
az account set --subscription "<your subscription>"
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

cd ~/istio-workshop/stack-1-cluster
tofu init
tofu apply                                     # 5 to 10 minutes
eval "$(tofu output -raw get_credentials)"     # writes ~/.kube/config
kubectl get nodes
```

## State

Local, in `terraform.tfstate` in this folder (gitignored). Stack 2 reads it, so don't delete it while stack 2 exists. **The state lives on the instructor's VM**: if the VM is destroyed before you run the destroy below, the cluster stays in your subscription and keeps costing you. If that happens, remove it with `az group delete -n rg-istio-ws-<attendee> --yes --no-wait`.

## Destroy

Do this before the VM goes away. Destroy stack 2 first, then this one: `scripts/down.sh`, or by hand:

```bash
tofu -chdir=../stack-2-mesh destroy
tofu destroy
az logout
```

## Notes

- Not hardened for production: Free tier (no uptime SLA), default network, local accounts. It suits a throwaway sandbox.
- `kube_config` is a sensitive output with cluster-admin credentials. Don't paste it anywhere.
- The provider doesn't register Azure resource providers (`resource_provider_registrations = "none"`). You do it once in lab 0.
- Conditional-access policies in your organisation may block sign-in from the VM (a different IP and device), or the device-code flow. Test the sign-in before the session.
