# Lab 1: sidecars and the services (15 min)

Stack 2 (lab 0) already deployed the services from `labs/apps/`. Look at what injection did.

```bash
kubectl -n apps get pods                 # READY should be 2/2
kubectl -n apps get pod -l app=edge -o jsonpath='{.items[0].spec.containers[*].name}'
istioctl proxy-status
kubectl -n external get pods             # 1/1: no sidecar, outside the mesh
```

Questions:
1. Which container is the sidecar? Which pods have none, and why?
2. What happens if you label `external` with `istio-injection=enabled` and restart? (Don't keep it: lab 6 needs it unlabelled.)

Checkpoint: pods in `apps` show 2/2 and `istioctl proxy-status` lists them.
