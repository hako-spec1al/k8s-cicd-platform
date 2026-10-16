# Context Handoff

Last updated: 2026-10-16

## Repository and Branch

- Repository: `k8s-cicd-platform`.
- Active branch at the Phase 9 baseline: `main`.
- Do not merge directly into `main`.
- Argo CD Application `platform-api-dev` targets `main` and deploys to `platform-dev`. At baseline, it was `Synced` and `Healthy` at commit `97b74a3b57c06439e7185aa8673e76f8c00054de`.

## Verified

- The Codespaces k3d cluster is running Argo CD, kube-prometheus-stack, and the FastAPI application.
- API routes, including `/metrics`, have returned HTTP 200 through port-forwarding; the API target is UP in Prometheus.
- Grafana, Argo CD, and Prometheus UIs have been accessible.
- The four-panel Grafana dashboard is provisioned from `monitoring/dashboard/dashboard.json` through the `grafana_dashboard=1` ConfigMap sidecar; sidecar logs confirmed dashboard reload returned HTTP 200.
- The three API alert rules are discovered by Prometheus. They were last observed as `Inactive (3)`, which is expected when conditions are not met.
- Phase 8 is complete. The user reports that verification screenshots have been captured; they have not yet been added to the repository.
- Running the compound task `Port-forward: All services (8000, 3000, 8082, 9090)` manually works.
- The CI workflow was updated and merged to build images from `phase-8-observability` and open an image-tag update PR back to that branch.
- The Phase 9 PR adds Gitleaks and a blocking Trivy image scan. The latest reported PR checks passed after Python package remediation; the PR has not been merged, so the `main` push/publish path is not yet verified.

## Port-forward Follow-up

- The four port-forward tasks work when run manually. If automatic startup is revisited, validate the current `.vscode/tasks.json` problem matcher; its `file` value is a string rather than a capture-group index.
- Port-forward automation is a Codespaces convenience follow-up and does not block Phase 8 completion.

## Phase 9 Baseline

- Phase 9 is in progress. Baseline and current implementation status are recorded in [`docs/phases/phase-9-security-reliability.md`](phases/phase-9-security-reliability.md).
- Gitleaks 8.30.1 scanned 28 commits and reported six false positives: Grafana query UUID identifiers at three dashboard locations repeated across two commits. No confirmed credential was found.
- The historical Trivy baseline reported 49 HIGH package-vulnerability records across 13 unique CVEs and no CRITICAL findings. After Python package remediation, the Phase 9 PR's blocking Trivy check passed; Gitleaks also passed. The PR is still unmerged.
- The earlier note that Argo CD tracks `phase-8-observability` was stale; the live Application targets `main`.
- Phase 8 screenshots remain a separate documentation follow-up.
- The Python package vulnerability remediation and CI verification are documented in [`docs/incidents/2026-10-python-package-vulnerabilities.md`](incidents/2026-10-python-package-vulnerabilities.md).

## Next Phase 9 Work

1. Review and merge the Phase 9 PR after confirming required checks pass on its latest commit.
2. Verify the `main` push path, including successful GHCR push after Trivy and the expected deployment PR behavior.
3. Review RBAC and NetworkPolicy, then test and document rollout recovery and rollback.

## Operational Cautions

- Do not run `setup-codespaces.sh` just to reopen ports. It deletes and recreates the `platform` cluster.
- Do not record passwords, tokens, or other secrets in this file.
- Before changing code, inspect `git status` and the relevant diffs; preserve existing user changes.

## First Checks When Resuming

```bash
git status --short --branch
kubectl config current-context
kubectl get nodes -o wide
kubectl get applications -n argocd
kubectl get servicemonitor,prometheusrule -A
```
