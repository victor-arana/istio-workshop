# Labs

Run every lab on your workshop VM, against the cluster you create in lab 0. New shells run `labs/env.sh` automatically: it shows the prompt `[sandbox <name>]` and checks the cluster name. Names use `workshop.example.com`; nothing here is a real host, IP or token.

| Lab | Folder | Tag |
| --- | --- | --- |
| 0 | `00-setup` cluster check | |
| 1 | `01-sidecars` | |
| 2 | `02-virtualservices` | |
| 3 | `03-authorization` | `[cloud]` |
| 4 | `04-headers` | |
| 5 | `05-domains-tls` | |
| 6 | `06-egress-mtls` | |
| 7 | `07-lock-egress` | |
| 8 | `08-telemetry` | |

Each folder holds a `README.md` with the tasks, starter YAML where useful, and a `solution/` folder with the finished YAML. Run `istioctl analyze -A` after each lab.

`labs/apps/` holds the sample services; stack 2 applies it in lab 0, so you normally don't.

`env.sh` also sets `GW_IP` (the gateway's public IP) and `MY_IP` (this VM's public IP, which is fixed, for lab 3). Run `source ~/istio-workshop/labs/env.sh` again if the gateway IP was not ready yet.
