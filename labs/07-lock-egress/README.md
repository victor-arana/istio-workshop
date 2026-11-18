# Lab 7: lock egress down (30 min)

Egress is open by default (`ALLOW_ANY`): the sidecar sends unknown destinations through `PassthroughCluster`.

1. Turn on access logs for `client` (apply `../08-telemetry/solution/access-logs-on.yaml`, retargeted at `app: client` - the sample in `solution/` does it).
2. Make calls: `example.com`, `core-api.workshop.example.com`, and `https://www.example.org` (a host without a ServiceEntry).
3. Read `kubectl -n apps logs deploy/client -c istio-proxy | tail`. External hosts you have no ServiceEntry for show `PassthroughCluster`.
4. Create ServiceEntries for the destinations you want to keep (lab 6 already made two).
5. Switch to `REGISTRY_ONLY`:
   ```bash
   helm upgrade istiod istio/istiod -n istio-system --version 1.32.0 --reuse-values \
     --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
   kubectl -n apps rollout restart deploy
   ```
   (`helm repo add istio https://istio-release.storage.googleapis.com/charts` first if needed.)
6. Repeat the calls: listed hosts work, `www.example.org` fails (HTTP 502 / connection reset).

Run `scripts/restore-egress.sh` to go back to `ALLOW_ANY`.

Checkpoint: before the allow-list, the logs show `PassthroughCluster` for external hosts, and afterwards only listed hosts work.
