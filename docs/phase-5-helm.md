# Phase 5: Helm Chart Standardization

## Goal

Convert the Phase 4 Kubernetes manifests into a Helm Chart to manage configuration flexibly across multiple environments

## Structure

```text
helm/platform-api/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-staging.yaml
└── templates/
    ├── _helpers.tpl
    ├── configmap.yaml
    ├── secret.yaml
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```
