# Incident Report: CI Build Failed with GHCR Anonymous Token 403

- **Date recorded:** 2026-10-14
- **Environment:** GitHub Actions
- **Status:** Resolved

## Symptoms

The `Build image locally` step failed with a GHCR `403 Forbidden`
while Buildx requested an anonymous token with pull/push scope.

## Cause

The build step was configured with both `load: true` and `push: true`.
Buildx attempted to push the image before the later GHCR login step.

## Impact

The CI image build and subsequent Trivy scan did not complete.

## Resolution

Set `push: false` on the local build step. Kept `load: true` so Trivy
could scan the image from the runner's Docker daemon. The workflow logs
in to GHCR and pushes the scanned image only afterward, on push events.

## Verification

The Phase 9 pull request subsequently passed the local image build and
Trivy scan after `push: false` was set on the build step. The pull request
does not log in to or push an image to GHCR. The post-merge `main` push
and GHCR publication path still requires verification.

## Prevention

Keep local build, scan, registry login, and push as separate steps in
that order. Do not enable registry push on the local build step.