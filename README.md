# Istio on AKS workshop

A hands-on workshop. You (the instructor) provide each attendee with a VM, in your subscription. Attendees SSH to it from their own computer, sign in to **their own Azure subscription** from the VM, create their own AKS cluster there with OpenTofu, install upstream Istio 1.32 on it, and run the labs with `kubectl` and `istioctl` from the VM.

This README is the instructor's runbook: follow it top to bottom. The labs are in `labs/`, and the full plan is in `../Istio on AKS workshop plan.md`.

```text
istio-workshop/
├── workstation/       INSTRUCTOR: one VM per attendee (your subscription), in two variants:
│   ├── minimal/       bare VM: attendees install the tools
│   ├── preinstalled/  tools installed and repository cloned on first boot
│   └── modules/vm/    code shared by both
├── stack-1-cluster/   ATTENDEE, on the VM: creates their AKS cluster in their own subscription
├── stack-2-mesh/      ATTENDEE, on the VM: Istio (Helm), gateway, Kiali, Prometheus, sample apps, mock core API
├── labs/              00-setup to 08-telemetry, each with YAML, a README and a solution/ folder
├── self-study/        routing, resilience, strict mTLS, ambient, and kind instructions
└── scripts/           install-tools.sh, up.sh, down.sh, certificates.sh, restore-egress.sh (run on the VM)
```

## How it works

```text
your subscription                       each attendee's OWN subscription
─────────────────                       ────────────────────────────────
tofu apply (workstation/<variant>)
  └─ vm-istio-ws-<attendee>  ◄── ssh ── attendee's computer
        │  (minimal VM only: attendee installs git, curl, az, kubectl, helm, tofu, istioctl)
        │  az login --use-device-code   ───────────►  attendee signs in
        │  tofu apply (stack-1-cluster) ───────────►  rg-istio-ws-<attendee> + AKS cluster
        │  tofu apply (stack-2-mesh)    ───────────►  Istio, gateway, Kiali, Prometheus, apps
        └─ kubectl / istioctl / labs 1 to 8 against that cluster
```

- The VM has **no Azure permissions** of its own. Everything the attendee creates uses their own `az login`, in their own subscription, so cost, quota and policies are theirs, and you have no access to their resources.
- The attendee's `tofu` state is local on the VM. Your state (the VMs) is a local file on your machine, in `workstation/<variant>/terraform.tfstate`: keep it until you run `tofu destroy`.
- **Teardown has two parts:** each attendee destroys their own cluster (`scripts/down.sh`, then `az logout`) before you run `tofu destroy` in `workstation/<variant>`, which removes only the VMs. You can't delete clusters in their subscriptions.

## 1. Prerequisites (instructor machine)

Install `tofu` (1.8 or newer) and `az`. Then:

```bash
az login
az account set --subscription <sandbox-subscription-id>

```

In your subscription, you need VM quota for the workshop VMs: 2 vCPUs per attendee, plus one spare. This workshop is planned for up to 4 attendees: 4 VMs use 8 vCPUs, and a spare makes 10, which is a typical default regional limit. If you run your own rehearsal cluster in the same subscription (6 more vCPUs), do it before creating the attendees' VMs, or destroy it first.

```bash
az vm list-usage -l <region> -o table | grep -iE "BS|Total Regional"
az aks get-versions -l <aks_location> -o table      # pick kubernetes_version
```

Each **attendee's** subscription needs AKS quota: with the defaults, 3 × 2 vCPUs of `Standard_D2s_v5` in `aks_location`. Attendees register the AKS resource providers in lab 0.

**What each attendee needs, before the day:** an Azure subscription where they can create resource groups and AKS clusters (Contributor or Owner), preferably a sandbox, with that vCPU quota, and an account that can sign in from your VM with the device-code flow. Ask them to test `az login --use-device-code` from any machine, and check your organisation's conditional-access policies don't block sign-in from an Azure VM's IP.

## 2. Choose the VM variant and configure

| Variant | What the VM has | Pick it when |
| --- | --- | --- |
| `workstation/preinstalled` | All tools installed and the repository cloned | Time is short, or the audience is here for Istio |
| `workstation/minimal` | A bare Ubuntu VM: attendees install the tools in lab 0 (about 10 more minutes) | You want attendees to set up their own tooling |

Apply one at a time. Both are described in `workstation/README.md`.

```bash
VARIANT=preinstalled        # or: minimal
cp workstation/$VARIANT/terraform.tfvars.example workstation/$VARIANT/terraform.tfvars
```

Edit it: `subscription_id` (yours), `location`, `ssh_allowed_cidrs` (office or VPN egress ranges), `repo_url` (push this repository somewhere the VMs can clone), `delete_after`, `kubernetes_version`, and `attendees` (name to SSH public key). `*.tfvars` files and the local state (`terraform.tfstate`) are gitignored.

## 3. Test with one attendee first

Set `attendees` to just `attendee-01` with your own key, then:

```bash
tofu -chdir=workstation/$VARIANT init
tofu -chdir=workstation/$VARIANT apply
tofu -chdir=workstation/$VARIANT output ssh_commands
```

Then do the attendee's part yourself:

```bash
ssh workshop@<ip>
cloud-init status --wait           # wait for "done" (preinstalled variant installs tools here)
```

Then follow `labs/00-setup/README.md` (tools if the VM is bare, then create your cluster), and the labs after it, using a stopwatch and only the lab READMEs, not `solution/`. Where you get stuck, fix the README. Do this from a typical attendee computer and VPN. Time lab 0: AKS creation and the Helm installs are the longest steps.

Things to confirm on this first run (they haven't been run before):

- `az login --use-device-code` works from the VM with a real attendee account, and the subscription you test with has quota. Conditional-access policies can block it.
- `tofu init` and `tofu apply` work in both stacks on the VM, using the attendee's `az login` and `ARM_SUBSCRIPTION_ID`.
- `az aks get-credentials` and `kubectl` work from the VM.
- Helm chart names and the 1.32.0 version, azurerm attribute names, the Ubuntu image, and the install commands in `scripts/install-tools.sh`.

Then clean up your test: `scripts/down.sh` on the VM (it destroys your cluster in **your** subscription), then `tofu -chdir=workstation/$VARIANT destroy`.

## 4. Build for everyone (day before)

1. List every attendee in `workstation/$VARIANT/terraform.tfvars` plus one spare (set `VARIANT` again if you opened a new shell). Collect SSH public keys a week ahead.
2. `tofu -chdir=workstation/$VARIANT apply`.
3. Send each attendee their own `ssh workshop@<ip>` command, and test every login.
4. Check `cloud-init status` reports `done` on every VM.
5. Confirm every attendee has a subscription ready: Contributor or Owner, AKS quota in `aks_location`, and a tested `az login --use-device-code`. Each attendee should set their own budget alert.

Attendees create their clusters themselves, in their own subscriptions, so nothing else is pre-built. To save session time, ask them to sign in and start `scripts/up.sh` (or lab 0 steps 1 to 4) during your welcome and talk. You can't pre-run it for them, because it needs their sign-in.

## 5. During the session

Follow the timings in the plan. Each lab has a README and a `solution/` folder.

- **Reset an attendee's labs** without recreating the cluster: on their VM, `tofu -chdir=~/istio-workshop/stack-2-mesh destroy` then `apply`.
- **Lab 7 recovery:** `scripts/restore-egress.sh` on the VM puts egress back to `ALLOW_ANY`.
- **A stuck attendee:** Pair them with a neighbour, or give them the spare VM and a working subscription.
- **Kiali:** `ssh -L 20001:localhost:20001 workshop@<ip>`, `kubectl port-forward svc/kiali 20001:20001 -n istio-system` on the VM, then `http://localhost:20001`.

## 6. Teardown (right after the session)

1. **Each attendee** runs `scripts/down.sh` on their VM (the wrap-up lab) and then `az logout`. It destroys their cluster and resource group in their own subscription. This must happen **before** you remove the VMs: their OpenTofu state is on the VM, and you can't delete resources in their subscriptions.
2. Ask each attendee to confirm `az group list --tag purpose=istio-workshop -o table` is empty in their subscription. If a cluster was orphaned, they remove it with `az group delete -n rg-istio-ws-<attendee> --yes --no-wait`.
3. You remove the VMs:

```bash
tofu -chdir=workstation/$VARIANT destroy
```

Files on the VMs are deleted, so tell attendees to push anything worth keeping. Then check your subscription with `az vm list -o table` and `az group list --tag purpose=istio-workshop -o table`.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| SSH to the VM times out, but the VM is running and the rule looks right | The IP you allowed isn't the one SSH leaves from. Behind a corporate proxy or VPN, `curl ifconfig.me` shows the **proxy's** IP. Use `curl --noproxy '*' https://ifconfig.me` (or the egress range your network team gives you) for `ssh_allowed_cidrs`, then `tofu apply` |
| SSH to the VM times out, and `az vm get-instance-view` says `VM deallocated` | The daily auto-shutdown switched the VM off (`shutdown_time` in `shutdown_timezone`, default 21:00 UTC). Start it with `scripts/start-vms.sh <attendee>` (or `az vm start -g rg-istio-ws-vms -n vm-istio-ws-<attendee>`): the static public IP stays the same. Set `shutdown_time` and `shutdown_timezone` in `terraform.tfvars` to an hour after your session or rehearsal ends, then run `tofu apply`; for a workshop day, start every VM in the morning |
| SSH worked before and now times out, and the VM is running | Your public IP changed (dynamic address, another network or a VPN), so the firewall no longer allows it. Compare `curl --noproxy '*' https://ifconfig.me` with `ssh_allowed_cidrs`, update the value and run `tofu apply`: only the firewall rule changes |
| `az login` fails or is blocked | Conditional access (compliant device, trusted location) or the device-code flow is blocked for that account. Test beforehand; use a sandbox account |
| `tofu apply` on the VM fails with an authorization or subscription error | The attendee isn't signed in to the right subscription: `az account show`, and `export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)` in that shell |
| `tofu init` is slow or fails on the VM | Provider downloads. Retry |
| Stack 2 can't read stack 1's state | Stack 1 isn't applied, or its `terraform.tfstate` is missing from `stack-1-cluster/` |
| Stack 2 fails on `kubectl` or `openssl` | `kubectl` isn't pointing at the cluster (run `get_credentials` from stack 1), or the tools aren't installed |
| Cluster creation fails with a provider or quota error | A resource provider isn't registered in the attendee's subscription (lab 0), or its vCPU quota in `aks_location` is short |
| Pods in `apps` show 1/1 | The namespace label came after the pods: `kubectl -n apps rollout restart deploy` |
| Gateway has no external IP | The load balancer is still provisioning. Wait, then `source ~/istio-workshop/labs/env.sh` |
| `workstation` apply fails on `Microsoft.DevTestLab` or another resource provider | Registration needs rights on the subscription (Contributor or Owner). Register by hand: `az provider register --namespace Microsoft.DevTestLab` |

## What hasn't been verified

This project has not been run against Azure. Confirm in your rehearsal: Helm chart names and the 1.32.0 version, azurerm attribute names and versions, the Ubuntu image, the install commands in `scripts/install-tools.sh`, sign-in from the VM, and the Kubernetes version, VM sizes and node count.
