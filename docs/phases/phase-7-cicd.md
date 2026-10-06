# Phase 7: CI/CD Integration

## Objective

Connect successful image builds to deployment configuration changes while retaining review and deployment history in Git.

## Implemented Workflow

1. Pull requests run the test suite.
2. Pushes to `main` and `phase-8-observability` that pass tests build and push a SHA-tagged image to GHCR. Pushes that only update `helm/platform-api/values-dev.yaml` are ignored to prevent a deployment-PR loop.
3. The workflow uses `yq` to update `image.tag` and `appVersion` in `helm/platform-api/values-dev.yaml`.
4. GitHub Actions opens a deployment PR against the branch that triggered the build. Merge that PR into the branch Argo CD currently tracks to deploy the new image.

The workflow uses `GITHUB_TOKEN` through GitHub Actions permissions rather than storing a token in YAML. The project identifies tag `v0.7.0` as the Phase 7 milestone.

## Branch Strategy

During Phase 8 verification, the Argo CD Application tracks `phase-8-observability`, so image-update PRs from that branch target it too. When Phase 8 is merged into `main` and `main` becomes the deployment source of truth, update the Application's `targetRevision` to `main` through Git.

## Related Files

- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)
- [`helm/platform-api/values-dev.yaml`](../../helm/platform-api/values-dev.yaml)
- [`argocd/application-platform-api.yaml`](../../argocd/application-platform-api.yaml)
