# Phase 3: CI Pipeline

## Objective

Run automated checks on code changes and publish a container image after changes reach `main`.

## Implementation

The current workflow runs on pull requests and pushes to `main`:

1. Checks out the source and sets up Python 3.11.
2. Installs dependencies from `requirements.txt`.
3. Runs `python -m pytest -q`.
4. On pushes to `main`, builds and pushes a commit-SHA-tagged image to GHCR.

The workflow also opens a deployment PR to update the Helm image tag; this step is covered in [Phase 7](phase-7-cicd.md).

## Scope and Limitations

- Pytest is the configured quality gate.
- The workflow reviewed for this documentation does not include linting, Trivy scanning, or Helm lint/template validation. These remain follow-up work and should not be reported as implemented.

## Related Files

- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)
- [`README.md`](../../README.md)
