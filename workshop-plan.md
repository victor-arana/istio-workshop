# Workshop plan: instructor steps

The short checklist for the instructor. The full runbook is `README.md`, and the full plan is `../Istio on AKS workshop plan.md`.

## 1. Decide, then collect (a week or more ahead)

- **VM variant:** `preinstalled` (tools ready, saves about 10 minutes) or `minimal` (attendees install the tools in lab 0).
- **From each attendee:**
  - an SSH **public** key
  - an Azure subscription (ideally a sandbox) where they can create resource groups and AKS clusters, with about 6 vCPUs of quota
  - confirmation that `az login --use-device-code` works for their account from outside their usual device
- **Network ranges:** your office or VPN egress ranges, for `ssh_allowed_cidrs`.
- **Git remote:** push this repository somewhere the VMs can clone, and note its URL.

## 2. Prepare your machine (once)

```bash
az login && az account set --subscription <your-subscription>
```

That is all the setup there is. OpenTofu keeps its state in a local file, and the provider registers the Azure resource providers it needs, so there is no storage account to create and no `az provider register` to run. You need Contributor or Owner on the subscription.

Find a Kubernetes version with `az aks get-versions -l <aks_location>`.

## 3. Configure

First choose `location` and `vm_size`: check the size is available to your subscription in that region, and that you have quota.

```bash
az account list-locations -o table
scripts/check-region.sh eastus2 westeurope        # SIZE=... to check another size, LIST=1 to list sizes
```

`restrictions 0` in the output means available. A restricted size (for example `NotAvailableForSubscription`) can't be created, even with quota: pick another region or size. Details in `workstation/README.md`.

`ssh_allowed_cidrs` must be the public IP your **SSH traffic** leaves from. On a corporate network with a web proxy, `curl ifconfig.me` shows the proxy's IP, not yours, and SSH will time out. Use `curl --noproxy '*' https://ifconfig.me` (or ask your network team for the egress range). For the attendees, use their office or VPN egress ranges.

Then:

```bash
VARIANT=preinstalled                       # or minimal
cp workstation/$VARIANT/terraform.tfvars.example workstation/$VARIANT/terraform.tfvars
```

Edit it: your `subscription_id`, `location`, `ssh_allowed_cidrs`, `repo_url`, `delete_after`, `kubernetes_version`, and `attendees` (name to SSH key).

## 4. Rehearse (at least two weeks before)

List only `attendee-01` with your own key, then:

```bash
tofu -chdir=workstation/$VARIANT init
tofu -chdir=workstation/$VARIANT apply
tofu -chdir=workstation/$VARIANT output ssh_commands
```

SSH in and do the attendee's part with a stopwatch, using only the lab READMEs. Sign in with an account like an attendee's, run labs 0 to 8, and then `scripts/down.sh` and `az logout`. Fix whatever breaks, then `tofu destroy`.

Nothing here has been run against Azure yet, so expect fixes. This is the first real test of the code.

## 5. The day before

1. List every attendee plus one spare in `terraform.tfvars`, then run `tofu apply`.
2. Send each attendee their `ssh workshop@<ip>` command and have them test the login. On the preinstalled variant, check `cloud-init status` says `done`.
3. Confirm every attendee has their subscription, quota and a working sign-in.
4. Ask each attendee to set a budget alert in their own subscription.

## 6. Session day

Follow the plan's timings.

- Attendees sign in and start `scripts/up.sh` (or lab 0) during your welcome and talk, so their clusters build while you speak.
- Help anyone stuck on sign-in, quota or permissions.

## 7. Teardown

1. Each attendee runs `scripts/down.sh`, then `az logout`, and checks `az group list --tag purpose=istio-workshop` is empty in their subscription. This must happen before you remove the VMs.
2. You run `tofu -chdir=workstation/$VARIANT destroy`.
3. Keep `workstation/$VARIANT/terraform.tfstate` until the destroy has finished.
