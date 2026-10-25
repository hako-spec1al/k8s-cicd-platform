# Phase 9: Security and Reliability

**Status:** In progress — CI security gate and RBAC least privilege are complete; NetworkPolicy and reliability verification remain (2026-10-25).

## Objective

Establish security and reliability controls for the existing CI/CD platform, including secret scanning, a blocking image-vulnerability gate, Kubernetes hardening, and recovery testing.

## Baseline

- Repository revision: `main`, commit `97b74a3b57c06439e7185aa8673e76f8c00054de`; working tree was clean.
- Deployment source: Argo CD `platform-api-dev` targets `main`, was `Synced` and `Healthy`, and reported the same revision. This resolves the stale `phase-8-observability` branch note in the context handoff.
- Historical baseline: CI at the baseline revision ran tests and built/pushed SHA-tagged images without Gitleaks or Trivy. The Phase 9 changes were merged, and the user reports that the updated image was deployed to `main` and its new Pods are healthy. The main-branch workflow and cluster state have not been independently inspected in this session.

### Gitleaks

- Version: 8.30.1.
- Scope: Git history; 28 commits scanned.
- Result: 6 `generic-api-key` detections across two historical commits. All six are false positives: three Grafana query UUID identifiers in `monitoring/dashboard/dashboard.json` at lines 98, 146, and 194, repeated across both commits. No confirmed credential was found.
- The report was redacted and only paths, line numbers, commit identifiers, and fingerprints were used for review. Do not commit raw scanner reports because they can contain secret values.
- Added narrow `.gitleaksignore` entries for the six confirmed historical Grafana UUID false positives. The Gitleaks CI check has passed. Do not broadly exclude the dashboard or weaken secret detection.

### Trivy

- Version: 0.75.0.
- Image: local-only `k8s-cicd-platform:p9-baseline-97b74a3b`, built from the repository Dockerfile; it was not pushed.
- Scope: vulnerability scanner, severities `HIGH,CRITICAL`. Report-only mode was used; no CI gate was changed.
- Result: 49 package-vulnerability records across 13 unique CVEs, all `HIGH`; no `CRITICAL` findings. Five package-vulnerability records reported a fixed version.
- Findings span Debian 13.7 packages in the `python:3.11-slim` image and Python dependencies, including Starlette, `jaraco.context`, and `wheel`.
- Unique CVEs: `CVE-2025-62727`, `CVE-2025-69720`, `CVE-2026-16742`, `CVE-2026-23949`, `CVE-2026-24049`, `CVE-2026-48818`, `CVE-2026-54283`, `CVE-2026-54369`, `CVE-2026-76642`, `CVE-2026-78408`, `CVE-2026-78409`, `CVE-2026-78410`, and `CVE-2026-9538`.
- This is the original baseline result, not the current image result. Subsequent remediation addressed vulnerable Python packages and pip-vendored packages; the updated image passed Trivy with the CI gate set to fail on HIGH/CRITICAL findings. See the [Python package vulnerability incident](../incidents/2026-10-python-package-vulnerabilities.md). The user reports that the PR was merged and the new Pods are running; the main-branch push-and-publish workflow has not been independently verified here.

### Current CI controls

- Gitleaks scans Git history, with only the confirmed Grafana UUID fingerprints ignored.
- Trivy scans the locally built image for HIGH and CRITICAL vulnerabilities, ignores unfixed findings, and fails the job when matching findings are present.
- The image is built locally without pushing, scanned, then logged in to GHCR and pushed only on push events after a successful scan.
- The Phase 9 checks passed before merge, according to the reported run. The user reports successful merge and healthy new Pods. Confirm the main-branch push/publish run from GitHub Actions before treating that path as independently verified.

### Existing runtime controls

- The Dockerfile creates and uses a non-root `appuser`.
- The active Helm deployment renders non-root execution, `allowPrivilegeEscalation: false`, a read-only root filesystem, dropped Linux capabilities, readiness/liveness probes, resource requests/limits, and a rolling update with `maxUnavailable: 0` and `maxSurge: 1`.
- Staging overrides resources; dev inherits the chart defaults.
- The standalone Kubernetes deployment additionally specifies `seccompProfile: RuntimeDefault` and a startup probe, but Argo CD deploys the Helm chart. Keep the chart as the effective deployment source unless that setup changes.

### RBAC and ServiceAccount review

- The active Argo CD application deploys `helm/platform-api` with `values-dev.yaml` into `platform-dev`.
- The user reports that GitOps RBAC hardening is complete: the API uses a dedicated ServiceAccount, its token is not mounted, and `kubectl auth can-i` checks deny the tested permissions as expected.
- No Kubernetes API client usage was found in the application Python source. The API therefore has no identified need for Kubernetes API permissions.
- The RBAC result is user-reported; this session has not independently inspected the merged Helm templates or live authorization state. Avoid adding Role/RoleBinding permissions unless a documented application feature requires specific Kubernetes API access.

### NetworkPolicy review

- No NetworkPolicy template or standalone NetworkPolicy manifest was found in the tracked repository files reviewed.
- The Helm Deployment and Service share selector labels from `platform-api.selectorLabels`: `app.kubernetes.io/name` and `app.kubernetes.io/instance`. Use this helper to select only the API Pods in a chart template.
- The ServiceMonitor is in `monitoring`, selects the API Service by `app.kubernetes.io/name: platform-api`, and scrapes its named `http` port at `/metrics`. This identifies the scrape target, but does not identify the Prometheus Pod labels needed as a NetworkPolicy source.
- The chart sets `ingressClassName: traefik`, but the repository does not define the live ingress-controller namespace or Pod labels. Discover both from the cluster; do not assume Traefik is in `kube-system` or that a guessed label matches.
- Proposed policy: isolate only the API Pods for ingress; allow TCP port 8000 from the verified ingress-controller Pods and Prometheus Pods; explicitly allow all egress temporarily. Confirm the cluster CNI enforces Kubernetes NetworkPolicy before treating the policy as an effective security boundary.
- `setup-codespaces.sh` creates the k3d cluster without installing or configuring an explicit NetworkPolicy-enforcing CNI. Verify the active CNI and policy enforcement before rollout; a NetworkPolicy object by itself does not guarantee traffic is filtered.
- Verify application readiness/liveness probes and Prometheus scraping after enabling the policy. Probe treatment can vary by network implementation.

## Baseline Commands

```bash
gitleaks git . --redact=100
docker build --tag k8s-cicd-platform:p9-baseline-<commit-short> .
trivy image --scanners vuln --severity HIGH,CRITICAL --exit-code 0 \
  k8s-cicd-platform:p9-baseline-<commit-short>
```

`--exit-code 0` is intentional for this historical baseline only. Current CI uses a blocking exit code for HIGH/CRITICAL findings.

## Next Work

1. Verify the main-branch workflow, including post-scan GHCR publication and the deployment PR behavior.
2. Add a scoped NetworkPolicy after confirming the live ingress-controller and Prometheus Pod labels and that the CNI enforces policies; verify ingress, probes, and metrics.
3. Exercise rolling update, failure recovery, and rollback; document evidence in the runbook.

## Related Files

- [CI workflow](../../.github/workflows/ci.yml)
- [Dockerfile](../../Dockerfile)
- [Helm deployment](../../helm/platform-api/templates/deployment.yaml)
- [Helm default values](../../helm/platform-api/values.yaml)
- [Standalone Kubernetes deployment](../../k8s/20-deployment.yaml)
- [Operations runbook](../runbooks/operational-commands.md)
- [GHCR build auth incident](../incidents/2026-10-ghcr-build-auth-403.md)
- [Python package vulnerability incident](../incidents/2026-10-python-package-vulnerabilities.md)
