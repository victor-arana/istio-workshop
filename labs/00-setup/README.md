# Lab 0: tools, sign-in and your cluster (25 min, 35 on a bare VM)

Your workshop VM is ready. The cluster does **not** exist yet: you create it with OpenTofu, from the VM. Cluster creation takes 5 to 10 minutes, so start it early and read while it runs.

Log in with the command the instructor sent: `ssh workshop@<vm-ip>`.

## 0. Tools (only if your VM is the bare one)

Check what is installed:

```bash
echo $WORKSHOP_NAME $WORKSHOP_REPO_URL
for t in git curl jq openssl az kubectl helm tofu istioctl; do command -v $t >/dev/null && echo "ok      $t" || echo "MISSING $t"; done
```

If everything shows `ok` (and `~/istio-workshop` exists), your VM came preinstalled: skip to step 1. Otherwise install the tools. You need these, and here is why:

| Tool | What it is for |
| --- | --- |
| `git` | Get the workshop repository |
| `curl`, `jq`, `openssl`, `envsubst` (`gettext-base`) | Download installers, read JSON, make certificates, fill variables in YAML |
| `az` (Azure CLI) | Sign in to **your** Azure subscription and fetch your cluster's credentials |
| `kubectl` | Talk to your cluster |
| `helm` | Used by stack 2 to install Istio |
| `tofu` (OpenTofu) | Create your cluster and mesh |
| `istioctl` | Inspect and debug the mesh |

Start with git and curl, then clone the repository:

```bash
sudo apt-get update && sudo apt-get install -y git curl
git clone "$WORKSHOP_REPO_URL" ~/istio-workshop
echo 'source "$HOME/istio-workshop/labs/env.sh"' >> ~/.bashrc
```

Then install the rest, either with the script (about 5 minutes) or by reading it and running the commands yourself:

```bash
cd ~/istio-workshop
less scripts/install-tools.sh          # read it first
scripts/install-tools.sh               # installs what is missing, then prints a check
scripts/install-tools.sh --check       # any time: shows ok or MISSING per tool
```

Open a new shell (or `source /etc/profile.d/workshop.sh`) so the environment is loaded.

## 1. Sign in to your own Azure subscription

The VM belongs to the instructor, but the cluster is created in **your** subscription, with your account. The VM holds no Azure permissions of its own.

```bash
az login --use-device-code          # open the URL it prints on your computer, enter the code, sign in
az account list -o table            # pick the subscription for the workshop
az account set --subscription "<name or id>"
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az account show -o table            # check it is the right one
```

Check you can create what the workshop needs:

```bash
echo $WORKSHOP_NAME $TF_VAR_location $TF_VAR_kubernetes_version
for p in Microsoft.ContainerService Microsoft.Compute Microsoft.Network Microsoft.Storage; do
  az provider register --namespace $p
done                                # needs Contributor (or Owner) on the subscription
az vm list-usage -l $TF_VAR_location -o table | grep -iE "DSv5|Total Regional"   # you need about 6 free vCPUs
```

`ARM_SUBSCRIPTION_ID` is what OpenTofu uses to choose your subscription, so set it in every new shell (or `scripts/up.sh` does it for you).

**Your credentials are on this VM** (in `~/.azure`) until you run `az logout`. Use a sandbox subscription, and sign out at the end of the session. Never sign in with an account whose subscription holds anything you can't afford to lose.

## 2. Create the cluster (stack 1)

```bash
cd ~/istio-workshop/stack-1-cluster
tofu init
tofu plan          # read it: a resource group and one AKS cluster, in your subscription
tofu apply         # type yes; takes 5 to 10 minutes
```

## 3. Connect kubectl

```bash
eval "$(tofu output -raw get_credentials)"
kubectl get nodes
```

If this fails with an authorization error, check that you are signed in to the right subscription (`az account show`).

## 4. Install the mesh and the sample apps (stack 2)

```bash
cd ../stack-2-mesh
tofu init
tofu apply         # Istio via Helm, ingress gateway, Kiali, Prometheus, namespaces, sample apps
```

`scripts/up.sh` does steps 2 to 4 in one go if you'd rather not type them (sign in first).

## 5. Check

```bash
source ~/istio-workshop/labs/env.sh     # sets GW_IP and MY_IP
kubectl get nodes
istioctl version
kubectl -n istio-system get pods        # istiod, istio-ingress, kiali, prometheus
kubectl get ns --show-labels            # apps has istio-injection=enabled
echo $GW_IP
```

Checkpoint: nodes are `Ready`, `istioctl version` shows client and control plane at 1.32.0, and `GW_IP` shows an address.

Kiali: on the VM run `kubectl port-forward svc/kiali 20001:20001 -n istio-system`, and connect from your computer with `ssh -L 20001:localhost:20001 workshop@<vm-ip>`, then open http://localhost:20001.

At the end of the session, **you** remove your cluster: `scripts/down.sh` (or `tofu destroy` in stack 2, then stack 1), then `az logout`. It is in your subscription, so it keeps costing you until it is deleted, and the instructor's cleanup of the VM can't remove it. Do this before the instructor destroys the VMs: the OpenTofu state lives on the VM.
