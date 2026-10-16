# Phase 9: Security and Reliability

**Status:** In progress — CI security changes and Python package remediation have passed PR checks; the PR is not yet merged (2026-10-16).

## Objective

Establish security and reliability controls for the existing CI/CD platform, including secret scanning, a blocking image-vulnerability gate, Kubernetes hardening, and recovery testing.

## Baseline

- Repository revision: `main`, commit `97b74a3b57c06439e7185aa8673e76f8c00054de`; working tree was clean.
- Deployment source: Argo CD `platform-api-dev` targets `main`, was `Synced` and `Healthy`, and reported the same revision. This resolves the stale `phase-8-observability` branch note in the context handoff.
- Historical baseline: CI at the baseline revision ran tests and built/pushed SHA-tagged images without Gitleaks or Trivy. The Phase 9 branch now adds both scanners; its PR checks have passed, but post-merge behavior on `main` has not yet been verified.

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
- This is the original baseline result, not the current image result. Subsequent remediation addressed vulnerable Python packages and pip-vendored packages; the updated PR image passed Trivy with the CI gate set to fail on HIGH/CRITICAL findings. See the [Python package vulnerability incident](../incidents/2026-10-python-package-vulnerabilities.md). The PR has not yet been merged, so the `main` push-and-publish path remains to be verified.

### Current CI controls

- Gitleaks scans Git history, with only the confirmed Grafana UUID fingerprints ignored.
- Trivy scans the locally built image for HIGH and CRITICAL vulnerabilities, ignores unfixed findings, and fails the job when matching findings are present.
- The image is built locally without pushing, scanned, then logged in to GHCR and pushed only on push events after a successful scan.
- The Phase 9 pull request checks have passed according to the latest reported run. Verify the checks again on the final PR commit and verify the push/publish path after merge.

### Existing runtime controls

- The Dockerfile creates and uses a non-root `appuser`.
- The active Helm deployment renders non-root execution, `allowPrivilegeEscalation: false`, a read-only root filesystem, dropped Linux capabilities, readiness/liveness probes, resource requests/limits, and a rolling update with `maxUnavailable: 0` and `maxSurge: 1`.
- Staging overrides resources; dev inherits the chart defaults.
- The standalone Kubernetes deployment additionally specifies `seccompProfile: RuntimeDefault` and a startup probe, but Argo CD deploys the Helm chart. Keep the chart as the effective deployment source unless that setup changes.
- No NetworkPolicy or dedicated Role/RoleBinding/ServiceAccount manifests were found in the tracked YAML files.

## Baseline Commands

```bash
gitleaks git . --redact=100
docker build --tag k8s-cicd-platform:p9-baseline-<commit-short> .
trivy image --scanners vuln --severity HIGH,CRITICAL --exit-code 0 \
  k8s-cicd-platform:p9-baseline-<commit-short>
```

`--exit-code 0` is intentional for this historical baseline only. Current CI uses a blocking exit code for HIGH/CRITICAL findings.

## Next Work

1. Review the Phase 9 PR, ensure all required checks pass on its latest commit, and merge through the repository's normal review process.
2. Verify the workflow on `main`, including post-scan GHCR publication and the deployment PR behavior.
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
