# Context Handoff

Last updated: 2026-09-27

## Repository Status

- Repository: `k8s-cicd-platform`.
- Active branch: `phase-8-observability`.
- Phases 1–7 are considered complete; Phase 7 milestone tag: `v0.7.0`.
- `setup-codespaces.sh` has an uncommitted change. Preserve it and inspect its diff before making further edits.

## Architecture

- FastAPI, Docker, GitHub Actions, and GHCR images tagged by commit SHA.
- Local Kubernetes via k3d; Helm chart at `helm/platform-api`.
- Argo CD Application `platform-api-dev` enables automated sync, pruning, and self-healing. Its current `targetRevision` is `phase-8-observability`, and its destination namespace is `platform-dev`.
- Low-footprint kube-prometheus-stack values are at `monitoring/kube-prometheus-stack-values.yaml`.
- The Windows/WSL host provides approximately 3.6 GB of Docker Desktop memory. Running k3d, Argo CD, and monitoring together caused resource starvation, Kubernetes API TLS timeouts, and `CrashLoopBackOff`. The lab is planned to move to a 4-core/8-GB Codespace using Docker-in-Docker.

## Phase 8 Status

- `.devcontainer/devcontainer.json` is present and runs `setup-codespaces.sh` through `postCreateCommand`.
- The bootstrap script recreates the `platform` cluster, installs Argo CD, installs monitoring, and then applies the Application. It has an uncommitted change and has not yet been verified in Codespaces.
- Prometheus instrumentation is present, but the app currently exposes `./metrics` while the ServiceMonitor expects `/metrics`.
- The ServiceMonitor template selects `app: platform-api` in namespace `platform`; the Helm Service uses the `app.kubernetes.io/name` label and Argo CD deploys it to `platform-dev`.
- A PrometheusRule template exists. There is no evidence yet that a dashboard has been created or that Prometheus targets and alerts have been verified.

## Next Steps

1. Review the existing `git diff` for the Dev Container and bootstrap files before committing.
2. Align the metrics endpoint and the ServiceMonitor selector/namespace; verify the Prometheus Operator selectors.
3. Validate the chart with `helm lint` and `helm template`.
4. Create a Codespace from the current branch, run the bootstrap, and verify Pod readiness and port forwarding.
5. Confirm the application target is UP, build a RED/resource dashboard, and test an alert with a controlled failure.
6. Capture evidence and update the README/phase docs; align Argo CD's target branch with the deployment PR base (`main`) after the branch is merged.

## Instructions for a New AI Session

Read this document first. Before editing, inspect Git status, `app/main.py`, the Helm monitoring templates, the Argo CD Application, and the bootstrap script. Do not claim Codespaces or Phase 8 is operational until fresh verification results are available.
