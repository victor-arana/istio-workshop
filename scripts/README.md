# Scripts

Helper scripts for the workshop. Run them from the repository root (`~/istio-workshop` on a workshop VM), for example `scripts/up.sh`.

| Script | Who runs it | Where | What it does |
| --- | --- | --- | --- |
| [`check-region.sh`](#check-regionsh) | Instructor, attendees | Anywhere with `az` | Checks a VM size and quota in a region |
| [`start-vms.sh`](#start-vmssh) | Instructor | Your machine, with `az` | Starts the VMs the daily auto-shutdown switched off |
| [`install-tools.sh`](#install-toolssh) | Attendees (bare VM) | Workshop VM | Installs the tools the workshop needs |
| [`up.sh`](#upsh) | Attendees | Workshop VM | Creates your cluster, mesh and sample apps |
| [`down.sh`](#downsh) | Attendees | Workshop VM | Destroys your mesh and cluster |
| [`certificates.sh`](#certificatessh) | Run by stack 2 | Workshop VM | Creates the certificates and secrets for the labs |
| [`restore-egress.sh`](#restore-egresssh) | Attendees | Workshop VM | Undoes the egress lock-down from lab 7 |

All scripts are plain Bash (`set -euo pipefail`). Make sure they are executable (`chmod +x scripts/*.sh`) if you copied the repository without file modes.

---

## check-region.sh

Checks whether a VM size is available to **your** subscription in one or more regions, and shows the vCPU quota. Use it before you choose `location` and `vm_size` (instructor), or `aks_location` and `aks_vm_size` (attendees). A size can be restricted for a subscription even when you have quota.

**Needs:** `az login`.

**List the available regions first**

```bash
az account list-locations -o table
```

Use the value from the `Name` column (for example `westeurope`, `eastus2`), not `DisplayName` ("West Europe"). To show only the physical regions, with a shorter list:

```bash
az account list-locations --query "[?metadata.regionType=='Physical'].{Name:name, DisplayName:displayName}" -o table
```

To find a region by name or keyword (for example, everything in Europe):

```bash
az account list-locations --query "[?contains(displayName, 'Europe')].{Name:name, DisplayName:displayName}" -o table
```

**Usage**

```bash
scripts/check-region.sh <region> [<region> ...]
SIZE=<vm-size> scripts/check-region.sh <region> ...
LIST=1 scripts/check-region.sh <region> ...
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `SIZE` | `Standard_B2s` | The VM size to check |
| `LIST` | unset | Set to `1` to also list the 2-vCPU sizes you can actually create: no restriction **and** quota in the size's family |

**Examples**

```bash
# Is Standard_B2s available in these regions, and what is the quota?
scripts/check-region.sh eastus2 eastus westus2

# Check the default AKS node size in the attendees' region
SIZE=Standard_D2s_v5 scripts/check-region.sh westeurope

# Standard_B2s is restricted in eastus2: list the sizes you can actually use there
LIST=1 scripts/check-region.sh eastus2
```

**Reading the output**

- With `LIST=1`, the last table lists sizes with `Restrictions 0` **and** a family quota above 0 (`FAMILY_LIMIT`). Those are the ones you can create. Keep the total within `Total Regional vCPUs`.
- In the size table, `restrictions` of `0` means you can create it. A number above `0` means a restriction such as `NotAvailableForSubscription`: pick another region or size. No row means the size isn't offered in that region.
- The quota lines show a name, current usage and limit. A `Standard_B2s` VM uses 2 vCPUs, so a limit of 10 fits 5 VMs.
- Valid region names come from `az account list-locations -o table` (see "List the available regions first" above).

---

## start-vms.sh

Starts the workshop VMs after the daily auto-shutdown switched them off, then shows each VM's state and public IP. A deallocated VM can't answer SSH, so connections time out until you start it. The VMs keep their static public IPs.

**Needs:** `az login`, in the instructor's subscription.

**Usage**

```bash
scripts/start-vms.sh                 # start every workshop VM
scripts/start-vms.sh attendee-01     # start one attendee's VM (several names allowed)
scripts/start-vms.sh --status        # only show state and IP, start nothing
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `RG` | `rg-istio-ws-vms` | The resource group that holds the VMs |

**Example**

```bash
$ scripts/start-vms.sh --status
Name                     State           Ip
-----------------------  --------------  -------------
vm-istio-ws-attendee-01  VM deallocated  20.127.25.131
$ scripts/start-vms.sh attendee-01
...
Name                     State       Ip
-----------------------  ----------  -------------
vm-istio-ws-attendee-01  VM running  20.127.25.131
$ ssh workshop@20.127.25.131
```

The same thing without the script: `az vm start -g rg-istio-ws-vms -n vm-istio-ws-attendee-01`.

To avoid nightly shutdowns while you rehearse, change `shutdown_time` and `shutdown_timezone` in `terraform.tfvars` and run `tofu apply`.

---

## install-tools.sh

Installs what the workshop needs on the VM (Ubuntu 24.04): `git`, `curl`, `jq`, `openssl`, `envsubst` (package `gettext-base`), the Azure CLI, `kubectl`, Helm, OpenTofu (`tofu`) and `istioctl`. It skips anything already installed, so it is safe to run twice.

On the `preinstalled` VM variant, first boot runs it for you. On the `minimal` VM, you run it in lab 0 (or run the same commands by hand: the script is the list).

**Needs:** `sudo` (the script uses it when you aren't root) and internet access. `git` and `curl` must already be there to fetch the repository and the script (`sudo apt-get install -y git curl`).

**Usage**

```bash
scripts/install-tools.sh            # install whatever is missing, then print a check
scripts/install-tools.sh --check    # only report ok or MISSING per tool
ISTIO_VERSION=1.32.0 scripts/install-tools.sh   # choose the istioctl version
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `ISTIO_VERSION` | `1.32.0` | `istioctl` version to install. On the VM this is already exported |

**Example**

```bash
$ scripts/install-tools.sh --check
git        ok
curl       ok
jq         ok
openssl    ok
envsubst   ok
az         MISSING
kubectl    MISSING
helm       MISSING
tofu       MISSING
istioctl   MISSING
```

The exit code is `0` when everything is installed and `1` otherwise, so `--check` works in other scripts. After the script finishes, open a new shell so the VM's environment variables are loaded.

---

## up.sh

Builds your whole environment in one go: it checks you are signed in, registers the Azure resource providers, creates your resource group and AKS cluster (stack 1), fetches the cluster credentials, then installs Istio, the gateway, Kiali, Prometheus, the namespaces and the sample apps (stack 2). It is lab 0, steps 2 to 4, in a single command. Expect 10 to 20 minutes.

**Needs:** the tools installed, and you signed in to **your own** subscription first:

```bash
az login --use-device-code
az account set --subscription "<name or id>"
```

The script reads the subscription from `az account show`, so you don't export `ARM_SUBSCRIPTION_ID` yourself.

**Usage**

```bash
scripts/up.sh
```

**Example**

```bash
$ az login --use-device-code
$ az account set --subscription "My Sandbox"
$ scripts/up.sh
Subscription: My Sandbox (00000000-0000-0000-0000-000000000000)
==> resource providers
...
$ source labs/env.sh        # sets GW_IP and MY_IP, checks the cluster name
$ kubectl get nodes
```

It is idempotent: if it fails halfway (for example on a quota error), fix the problem and run it again. It stops with a message if you aren't signed in.

---

## down.sh

Destroys your mesh (stack 2) and then your cluster and resource group (stack 1), in **your** subscription. Run it at the end of the session.

**Run it before the instructor removes the VMs.** The OpenTofu state lives on the VM, and the instructor cannot delete resources in your subscription. If the VM goes first, the cluster keeps running and costing you money until you delete it by hand.

**Usage**

```bash
scripts/down.sh
az logout                # remove your sign-in from the VM
```

**Example**

```bash
$ scripts/down.sh
...
Check nothing is left: az group list --tag purpose=istio-workshop -o table
Then sign out so your credentials don't stay on this VM: az logout
$ az group list --tag purpose=istio-workshop -o table      # should print nothing
$ az logout
```

If the state is gone (the VM was recreated), delete the group directly: `az group delete -n rg-istio-ws-$WORKSHOP_NAME --yes --no-wait`.

---

## certificates.sh

Generates a small certificate authority and the certificates the labs need, and creates the Kubernetes secrets from them. Everything uses `example.com` names and expires in 30 days: nothing here is a real credential.

Stack 2 runs it for you after creating the namespaces, so you normally never call it. It is also what you run to recreate the secrets by hand.

**Creates**

| Secret | Namespace | Used for |
| --- | --- | --- |
| `core-api-tls` | `external` | The mock core API's server certificate, key and the CA that must sign client certificates |
| `core-api-client` | `apps` | The client certificate the sidecar presents to `core-api` (lab 6, `credentialName`) |
| `tls-backend-cert` | `apps` | The certificate `tls-backend` serves itself (lab 5, TLS passthrough) |

**Needs:** `openssl`, `kubectl` pointing at your cluster, and the `apps` and `external` namespaces to exist.

**Usage**

```bash
scripts/certificates.sh
CERT_DIR=/path/to/certs scripts/certificates.sh
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `CERT_DIR` | `<repo>/.certs/local` | Where the certificate files are written. They are gitignored |

**Examples**

```bash
# Recreate the secrets (the CA and certificates already in CERT_DIR are reused)
scripts/certificates.sh

# Start from a clean set of certificates
rm -rf .certs && scripts/certificates.sh

# Look at what was created
kubectl -n external get secret core-api-tls
kubectl -n apps get secret core-api-client tls-backend-cert
```

Lab 6 shows why the client certificate matters: with it `core-api` replies `"verified":"SUCCESS"`, and without it the call fails.

---

## restore-egress.sh

Puts the mesh's outbound traffic policy back to `ALLOW_ANY` after lab 7, where you switched it to `REGISTRY_ONLY` to block calls to hosts without a `ServiceEntry`. Use it if you are locked out of external calls, or to reset before redoing the lab.

**Needs:** `helm` and `kubectl` pointing at your cluster.

**Usage**

```bash
scripts/restore-egress.sh
ISTIO_VERSION=1.32.0 scripts/restore-egress.sh
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `ISTIO_VERSION` | `1.32.0` | The `istiod` chart version to upgrade. Must match what stack 2 installed |

**Example**

```bash
$ scripts/restore-egress.sh
...
Egress restored. Restart workloads in apps to pick it up immediately: kubectl -n apps rollout restart deploy
$ kubectl -n apps rollout restart deploy
$ kubectl -n apps exec deploy/client -c curl -- curl -s -o /dev/null -w '%{http_code}\n' https://www.example.org
```

Note: lab 7 changes this setting with `helm upgrade`, outside OpenTofu. If you later run `tofu apply` in stack 2, it may report that change as drift.

---

## Typical order

For an attendee on a workshop VM:

```bash
scripts/install-tools.sh       # bare VM only, once
az login --use-device-code && az account set --subscription "<name or id>"
scripts/up.sh                  # lab 0: cluster, mesh, apps
source labs/env.sh
# ... labs 1 to 8 ...
scripts/restore-egress.sh      # only if you need to undo lab 7
scripts/down.sh && az logout   # wrap-up
```

For the instructor, before choosing a region and size:

```bash
scripts/check-region.sh eastus2 westeurope
```
