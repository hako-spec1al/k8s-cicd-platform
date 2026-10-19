# Phase 9: Security and Reliability

**Status:** In progress — CI security gate is complete; RBAC hardening and reliability verification remain (2026-10-19).

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
- The Helm Deployment template does not set `spec.template.spec.serviceAccountName`, and the chart has no ServiceAccount, Role, RoleBinding, ClusterRole, or ClusterRoleBinding templates. Kubernetes therefore uses the namespace's `default` ServiceAccount unless the live workload has been changed outside this chart.
- The standalone `k8s/20-deployment.yaml` also does not set a ServiceAccount.
- No Kubernetes API client usage was found in the application Python source. The API therefore has no identified need for Kubernetes API permissions.
- Recommended least-privilege target: create a dedicated `platform-api` ServiceAccount in `platform-dev`, set `automountServiceAccountToken: false` on it (or on the Pod), and reference it from the Helm Deployment. Do not create a Role or RoleBinding unless a documented application feature later requires specific Kubernetes API access. This removes the unnecessary default token and grants no API permissions.
- This is a repository configuration review, not a live-cluster authorization audit. Check the rendered/live Pod ServiceAccount and its effective permissions before and after applying the change.
- No NetworkPolicy was found in tracked manifests; assess it separately against ingress and Prometheus scrape traffic.

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
2. Configure a dedicated ServiceAccount for the API with token automount disabled and no RBAC bindings; verify the rendered and live workload.
3. Review least-privilege RBAC and add a scoped NetworkPolicy if compatible with the application and monitoring setup.
4. Exercise rolling update, failure recovery, and rollback; document evidence in the runbook.

## Related Files

- [CI workflow](../../.github/workflows/ci.yml)
- [Dockerfile](../../Dockerfile)
- [Helm deployment](../../helm/platform-api/templates/deployment.yaml)
- [Helm default values](../../helm/platform-api/values.yaml)
- [Standalone Kubernetes deployment](../../k8s/20-deployment.yaml)
- [Operations runbook](../runbooks/operational-commands.md)
- [GHCR build auth incident](../incidents/2026-10-ghcr-build-auth-403.md)
- [Python package vulnerability incident](../incidents/2026-10-python-package-vulnerabilities.md)
