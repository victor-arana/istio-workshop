# Workstation: the attendees' VMs

**Run by the instructor.** Creates one Ubuntu VM per attendee, in the instructor's subscription, and nothing else for the attendees. Attendees SSH to their VM from their own computer, sign in to **their own Azure subscription** with `az login`, create their own AKS cluster there with OpenTofu (`stack-1-cluster`, `stack-2-mesh`), and use `kubectl` against it.

The VM is only a workstation: it has no managed identity and no Azure permissions, so it can't touch the instructor's subscription or anyone else's.

There are two variants. **Apply one of them**, not both: they create the same resource names.

| Directory | VM on first boot | Use it when |
| --- | --- | --- |
| `minimal/` | A bare Ubuntu 24.04 VM. Nothing installed: not even the repository. The attendee installs `git`, `curl`, `kubectl`, `az`, Helm, OpenTofu and `istioctl` themselves, in lab 0 | The setup is part of what you want to teach, or you want attendees to see what the labs depend on |
| `preinstalled/` | Everything installed and the repository cloned (`~/istio-workshop`). Attendees go straight to creating their cluster | Time is short, or the audience is here for Istio, not for tooling |

```text
workstation/
├── modules/vm/       shared code: resource group, network, NSG, VMs, auto-shutdown
│   ├── cloud-init-minimal.yaml        only the environment variables
│   └── cloud-init-preinstalled.yaml   environment variables, then clone and scripts/install-tools.sh
├── minimal/          root module: install_tools = false      (state key workstation-minimal)
└── preinstalled/     root module: install_tools = true       (state key workstation-preinstalled)
```

The two root directories differ only in `install_tools` and the state key. Their `variables.tf` files are identical (`diff minimal/variables.tf preinstalled/variables.tf` shows nothing), so keep them in sync if you change one.

The tool installation lives in one place: `scripts/install-tools.sh` in the repository. The preinstalled VM runs it on first boot, and a minimal VM's attendee runs it (or the same commands by hand) in lab 0.

## What it creates

For an explanation of each resource and a diagram of how they connect, see [`architecture.md`](architecture.md).

- Resource group `rg-istio-ws-vms`, a virtual network, a subnet, and a network security group that allows SSH (22) only from `ssh_allowed_cidrs`.
- Per attendee: a static public IP, a network interface, and an Ubuntu 24.04 VM (`vm-istio-ws-<attendee>`, SSH-key login for the user `workshop`).
- A daily auto-shutdown schedule per VM.

The attendees' clusters are not created here. Each attendee creates theirs from their VM, in their own subscription, so destroying this stack does **not** remove them: see Destroy.

## What both variants put on the VM

`/etc/profile.d/workshop.sh`, loaded by every login shell:

- `TF_VAR_attendee`, `TF_VAR_location`, `TF_VAR_kubernetes_version`, `TF_VAR_vm_size`, `TF_VAR_node_count`, `TF_VAR_delete_after`, `TF_VAR_istio_version`: the stacks need no `tfvars` on the VM.
- `WORKSHOP_NAME`, `WORKSHOP_REPO_URL` and `ISTIO_VERSION`.

There is no subscription or identity here: the attendee signs in with `az login` and exports `ARM_SUBSCRIPTION_ID` (lab 0).

The minimal variant stops there, so an attendee can `git clone "$WORKSHOP_REPO_URL"` once git is installed.

## Inputs

| Variable | Required | Default | Notes |
| --- | --- | --- | --- |
| `subscription_id` | yes | | The **instructor's** subscription, where the VMs live |
| `location` | yes | | Region of the VMs |
| `attendees` | yes | | Map of attendee name to SSH **public** key |
| `ssh_allowed_cidrs` | yes | | Public IPs or ranges SSH leaves from: office or VPN egress ranges. Behind a web proxy, `curl ifconfig.me` shows the proxy's IP, not the one SSH uses: find yours with `curl --noproxy '*' https://ifconfig.me` |
| `repo_url` | yes | | Git URL of this repository |
| `delete_after` | yes | | Tag value, also given to the attendee's cluster |
| `aks_location` | no | same as `location` | Region where attendees create their clusters, in their own subscriptions |
| `kubernetes_version` | yes | | AKS version for the attendees' clusters, from `az aks get-versions` |
| `vm_size` | no | `Standard_B2s` | Workshop VM size |
| `aks_vm_size`, `aks_node_count` | no | `Standard_D2s_v5`, `3` | Node size and count of each attendee's cluster |
| `istio_version` | no | `1.32.0` | Used by `istioctl` and stack 2 |
| `shutdown_time`, `shutdown_timezone` | no | `2100`, `UTC` | Daily auto-shutdown time (`HHMM`) and the time zone it is in. The time zone is a Windows time zone ID, not `UTC-6`: use `Central America Standard Time` for UTC-6 all year (no daylight saving). Other UTC-6 IDs: `Central Standard Time` (US Central, shifts with daylight saving) and `Central Standard Time (Mexico)` |

## Choosing `location` and `vm_size`

`location` is an Azure region name such as `westeurope` (not "West Europe"). A region can fail even with quota, if a size is restricted for your subscription. Check before applying. All the commands are in a script, so there is nothing to copy:

```bash
az login
az account list-locations -o table                     # valid region names (Name column)

scripts/check-region.sh eastus2 eastus westus2         # is Standard_B2s available, and what is the quota
SIZE=Standard_D2s_v5 scripts/check-region.sh westeurope   # check another size
LIST=1 scripts/check-region.sh eastus2                 # also list sizes you can actually create (no restriction and family quota)
```

How to read it:

- In the size table, `restrictions` of `0` means you can create it. A row with `2` (for example `NotAvailableForSubscription`) means you can't: pick another region or size. No row means the size isn't offered there.
- The quota lines show `name, current usage, limit`. Each workshop VM needs 2 vCPUs (with `Standard_B2s`), so 10 vCPUs fit 5 VMs.
- Quota and availability are separate: you can have quota for a size you aren't allowed to create.

Then set `location` and `vm_size` in `terraform.tfvars`. The same script checks the attendees' side: have each attendee run `SIZE=Standard_D2s_v5 scripts/check-region.sh <aks_location>` in their own subscription (default cluster size `aks_vm_size`), and pick a `kubernetes_version` from `az aks get-versions -l <aks_location> -o table`.

## Prerequisites

- Rights to create resource groups and VMs in the instructor's subscription (Contributor or Owner). That is also what lets the provider register the resource providers it needs (Compute, Network, Storage, DevTestLab), so you don't run `az provider register`.
- Nothing else to create beforehand: no storage account, no backend. State is a local file (`terraform.tfstate`) in the variant's folder, so keep it until you run `tofu destroy`.
- A Git URL the VMs can reach (`repo_url`), pointing at this repository.
- **For each attendee:** an Azure subscription where they can create resource groups and AKS clusters, with vCPU quota (6 vCPUs with the defaults) in `aks_location`, and an account that can sign in from the VM. Collect these before the day.

## Use

```bash
cd workstation/preinstalled            # or workstation/minimal
cp terraform.tfvars.example terraform.tfvars   # then edit
tofu init
tofu apply
tofu output ssh_commands
```

Send each attendee their own `ssh workshop@<ip>` command. Create the VMs the day before.

- Preinstalled variant: wait for first boot to finish (`cloud-init status --wait` on the VM, and `~/.workshop-ready` exists), which takes a few minutes.
- Minimal variant: the VM is ready as soon as SSH works.

To switch variant, `tofu destroy` the one you applied before applying the other.

## Destroy

Attendees destroy their own clusters first (`scripts/down.sh` on the VM, then `az logout`), because the clusters are in their subscriptions and their OpenTofu state is on the VM. Then:

```bash
tofu destroy        # in the directory you applied
```

This removes the VMs, IPs and network, and deletes the attendees' files on the VMs, so tell them to push anything worth keeping. It does not delete clusters in attendee subscriptions: ask each attendee to confirm `az group list --tag purpose=istio-workshop -o table` is empty in their own subscription.

## Notes and things to confirm in the rehearsal

- Not run yet. Check the Ubuntu image, the commands in `scripts/install-tools.sh`, and the OpenTofu install script.
- The minimal VM relies on the stock Ubuntu image having `curl` and `apt`. If `git` is missing, that is the first thing the attendee installs.
- Test `az login --use-device-code` from a VM with a real attendee account. Conditional-access policies (compliant device, trusted location, blocked device-code flow) can stop it.
- Attendees' tokens sit on the VM in `~/.azure`, and you can administer the VM, so tell attendees to use sandbox subscriptions and `az logout` at the end.
- `delete_after` is a tag only. Nothing deletes anything automatically.
