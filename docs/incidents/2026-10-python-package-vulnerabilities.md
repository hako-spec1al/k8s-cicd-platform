# Incident Report: Trivy Reported Vulnerable Python Packages

- **Date recorded:** 2026-10-14
- **Environment:** Docker image build and Trivy scan in GitHub Actions
- **Status:** Resolved

## Symptoms

The Trivy image scan reported four HIGH findings for Python packages:

- `msgpack` GHSA-6v7p-g79w-8964, fixed in 1.2.1
- `setuptools` CVE-2025-47273, fixed in 78.1.1
- `urllib3` CVE-2026-97687 and CVE-2026-97689, fixed in 2.8.0

The report listed older installed versions even after the application
dependencies had been updated.

## Cause

The vulnerable versions were vendored inside pip under
`pip/_vendor/vendor.txt` (`msgpack` 1.1.2, `setuptools` 70.3.0, and
`urllib3` 2.7.0). Updating the standalone application packages did not
remove those copies, so Trivy continued to find them in the image.

## Impact

The container image failed the CI Trivy gate for HIGH-severity findings and
could not proceed through the normal image publication workflow.

## Resolution

- Added minimum fixed versions for `msgpack`, `setuptools`, and `urllib3` to
  [`requirements.txt`](../../requirements.txt).
- Updated pip, setuptools, and wheel before installing the application
  dependencies in the [`Dockerfile`](../../Dockerfile).
- Removed package-installation tooling from the final runtime image after
  installation. The API runs with Uvicorn and does not need pip at runtime.

No virtual environment was added: it would separate Python packages, but it
would not by itself remove vulnerable packages vendored inside pip.

## Verification

- Built the Docker image successfully.
- Confirmed pip, setuptools, and wheel are absent from the runtime image.
- The Trivy scan reported no HIGH or CRITICAL vulnerabilities.
- All four API tests passed.

## Follow-up

- Keep the runtime image limited to dependencies needed to run the service;
  install build and package-management tools only when needed.
- When Trivy reports versions that differ from `pip show`, inspect vendored
  package metadata and the image filesystem before changing application
  dependency constraints.
- Use the [Trivy build and scan runbook](../runbooks/build-and-scan-trivy.md)
  to rebuild and scan the image after dependency changes.
