# Phase 5: Helm Chart

## Objective

Package Kubernetes configuration as a reusable chart with environment-specific values.

## Implementation

The [`helm/platform-api/`](../../helm/platform-api/) chart includes templates for the ConfigMap, Secret, Deployment, Service, Ingress, and monitoring resources. `values.yaml` provides defaults; `values-dev.yaml` and `values-staging.yaml` override environment-specific settings.

## Validation and Operations

```bash
helm lint ./helm/platform-api
helm template platform-api ./helm/platform-api \
  --namespace platform-dev \
  -f ./helm/platform-api/values-dev.yaml
```

Argo CD currently renders the chart from Git. Routine direct `helm upgrade` operations against an Argo-managed release should be avoided because Argo CD may reconcile the cluster back to the Git-declared state.

Legacy Phase 5 page: [`docs/phase-5-helm.md`](../phase-5-helm.md).
