# Phase 9: Security and Reliability

**Status:** In progress — baseline recorded 2026-10-06.

## Objective

Establish security and reliability controls for the existing CI/CD platform, beginning with secret and image-vulnerability baselines before making either scanner a blocking CI gate.

## Baseline

- Repository revision: `main`, commit `97b74a3b57c06439e7185aa8673e76f8c00054de`; working tree was clean.
- Deployment source: Argo CD `platform-api-dev` targets `main`, was `Synced` and `Healthy`, and reported the same revision. This resolves the stale `phase-8-observability` branch note in the context handoff.
- CI: `.github/workflows/ci.yml` runs tests and builds/pushes SHA-tagged images, but does not currently run Gitleaks or Trivy.

### Gitleaks

- Version: 8.30.1.
- Scope: Git history; 28 commits scanned.
- Result: 6 `generic-api-key` detections across two historical commits. All six are false positives: three Grafana query UUID identifiers in `monitoring/dashboard/dashboard.json` at lines 98, 146, and 194, repeated across both commits. No confirmed credential was found.
- The report was redacted and only paths, line numbers, commit identifiers, and fingerprints were used for review. Do not commit raw scanner reports because they can contain secret values.
- Before making Gitleaks blocking in CI, handle these exact false positives narrowly; do not broadly exclude the dashboard or weaken secret detection.

### Trivy

- Version: 0.75.0.
- Image: local-only `k8s-cicd-platform:p9-baseline-97b74a3b`, built from the repository Dockerfile; it was not pushed.
- Scope: vulnerability scanner, severities `HIGH,CRITICAL`. Report-only mode was used; no CI gate was changed.
- Result: 49 package-vulnerability records across 13 unique CVEs, all `HIGH`; no `CRITICAL` findings. Five package-vulnerability records reported a fixed version.
- Findings span Debian 13.7 packages in the `python:3.11-slim` image and Python dependencies, including Starlette, `jaraco.context`, and `wheel`.
- Unique CVEs: `CVE-2025-62727`, `CVE-2025-69720`, `CVE-2026-16742`, `CVE-2026-23949`, `CVE-2026-24049`, `CVE-2026-48818`, `CVE-2026-54283`, `CVE-2026-54369`, `CVE-2026-76642`, `CVE-2026-78408`, `CVE-2026-78409`, `CVE-2026-78410`, and `CVE-2026-9538`.

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

`--exit-code 0` is intentional for this baseline only. The later CI integration should report HIGH/CRITICAL findings and fail according to the agreed gate policy.

## Next Work

1. Review and remediate the Trivy findings, prioritizing vulnerable direct/transitive Python dependencies and the base image.
2. Integrate only Gitleaks and Trivy (`HIGH,CRITICAL`) into CI; add narrow handling for the confirmed Grafana UUID false positives.
3. Review least-privilege RBAC and add a scoped NetworkPolicy if compatible with the application and monitoring setup.
4. Exercise rolling update, failure recovery, and rollback; document evidence in the runbook.

## Related Files

- [CI workflow](../../.github/workflows/ci.yml)
- [Dockerfile](../../Dockerfile)
- [Helm deployment](../../helm/platform-api/templates/deployment.yaml)
- [Helm default values](../../helm/platform-api/values.yaml)
- [Standalone Kubernetes deployment](../../k8s/20-deployment.yaml)
- [Operations runbook](../runbooks/operational-commands.md)
