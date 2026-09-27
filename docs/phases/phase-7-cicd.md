# Phase 7: CI/CD Integration

## Objective

Connect successful image builds to deployment configuration changes while retaining review and deployment history in Git.

## Implemented Workflow

1. Pull requests run the test suite.
2. A push to `main` that passes tests builds and pushes a SHA-tagged image to GHCR.
3. The workflow uses `yq` to update `image.tag` and `appVersion` in `helm/platform-api/values-dev.yaml`.
4. GitHub Actions opens a deployment PR against `main`; after it is merged, Argo CD reconciles the chart.

The workflow uses `GITHUB_TOKEN` through GitHub Actions permissions rather than storing a token in YAML. The project identifies tag `v0.7.0` as the Phase 7 milestone.

## Current Configuration Note

The Argo CD Application on the active branch targets `phase-8-observability`, while the deployment PR workflow targets `main`. Align the Argo CD target branch with the PR base before relying on the post-merge end-to-end deployment flow.

## Related Files

- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)
- [`helm/platform-api/values-dev.yaml`](../../helm/platform-api/values-dev.yaml)
- [`argocd/application-platform-api.yaml`](../../argocd/application-platform-api.yaml)
