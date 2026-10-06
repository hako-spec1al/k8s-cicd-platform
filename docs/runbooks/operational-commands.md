# Operations Runbook

The commands below assume a k3d cluster named `platform`. Check the active context before changing resources.

## Check the Context and Workloads

```bash
kubectl config current-context
kubectl get nodes -o wide
kubectl get pods -A
kubectl get events -A --sort-by=.lastTimestamp
```

## Argo CD and the Application

```bash
kubectl -n argocd get applications
kubectl -n argocd get pods
kubectl -n platform-dev get pods,svc,ingress
kubectl -n platform-dev rollout status deployment --timeout=180s
```

Find the exact Service name rendered by Helm before forwarding a port:

```bash
kubectl -n platform-dev get svc
kubectl -n platform-dev port-forward --address 0.0.0.0 svc/<service-name> 8000:8000
```

In Codespaces, open port `8000` from the **Ports** tab. Locally, use `http://127.0.0.1:8000/health`.

## Monitoring

```bash
kubectl -n monitoring get pods,svc
kubectl -n monitoring get servicemonitors,prometheusrules
kubectl -n monitoring port-forward --address 0.0.0.0 svc/monitoring-grafana 3000:80
```

The Grafana Service name may vary by Helm release; confirm it with `kubectl -n monitoring get svc`. Open port `3000` in Codespaces or browse to `http://127.0.0.1:3000` locally.

### Provision or refresh the Platform API dashboard

Grafana loads labeled dashboard ConfigMaps from the `monitoring` namespace. Run these commands from the repository root after changing `monitoring/dashboard/dashboard.json`:

```bash
kubectl create configmap platform-api-dashboard \
  --namespace monitoring \
  --from-file=dashboard.json=monitoring/dashboard/dashboard.json \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label configmap platform-api-dashboard \
  --namespace monitoring grafana_dashboard=1 --overwrite
```

The Grafana dashboard sidecar detects the ConfigMap and provisions the dashboard. Do not rerun `setup-codespaces.sh` just to refresh the dashboard; that script recreates the k3d cluster.

## Argo CD UI

```bash
kubectl -n argocd port-forward --address 0.0.0.0 svc/argocd-server 8082:443
```

Open port `8082` in Codespaces. Locally, browse to `https://127.0.0.1:8082`; the default certificate may be self-signed.

Retrieve the initial admin password if the bootstrap Secret still exists:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
printf '\n'
```

## Start or Stop the Local k3d Cluster

```bash
k3d cluster stop platform
k3d cluster start platform
kubectl config use-context k3d-platform
```

These k3d commands do not control a Codespaces cluster when it uses a different context or Docker daemon. Do not delete a cluster while it contains workloads or data you need to retain.

## Quick Diagnostics

```bash
kubectl -n monitoring describe pods
kubectl -n monitoring logs deployment/<deployment-name> --all-containers --tail=100
kubectl top nodes
kubectl top pods -A
```

`kubectl top` requires Metrics Server to be available. If metrics are unavailable on k3d, use `kubectl describe`, events, and restart counts as additional diagnostic evidence.


## Get password

for ArgoCD:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode
printf '\n'
```
for Grafana:

```bash
kubectl -n monitoring get secret monitoring-grafana \
  -o jsonpath='{.data.admin-password}' | base64 --decode
printf '\n'
```
