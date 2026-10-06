# Phase 6: GitOps with Argo CD

## Objective

Make Git the declarative source of truth and use Argo CD to synchronize the Helm release to Kubernetes.

## Implementation

[`argocd/application-platform-api.yaml`](../../argocd/application-platform-api.yaml) defines the `platform-api-dev` Application. It sources the chart from `helm/platform-api`, applies `values-dev.yaml`, and deploys to the `platform-dev` namespace. Automated sync, pruning, and self-healing are enabled.

## Verification

The expected Application state is `Synced` and `Healthy`. Git changes should reconcile to the cluster, and Argo CD should recreate resources that are manually deleted.

The Application currently targets `phase-8-observability` for Codespaces verification. When Phase 8 is merged into `main` and `main` becomes the deployment source of truth, update `targetRevision` to `main` through Git so Argo CD follows the intended branch.
