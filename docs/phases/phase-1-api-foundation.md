# Phase 1: API Foundation

## Objective

Build a small API with a stable contract to serve as the workload for the container and Kubernetes phases.

## Implementation

- FastAPI provides `GET /health`, `GET /ready`, and `GET /version`.
- The runtime version is configured through `APP_VERSION`, defaulting to `dev`.
- Pytest covers the responses from all three endpoints.

## Verification

```bash
python -m pytest -q
```

The current tests verify response status codes and payloads. Structured logging, graceful shutdown, and linting are not configured in the current application.

## Related Files

- [`app/main.py`](../../app/main.py)
- [`tests/test_main.py`](../../tests/test_main.py)
- [`requirements.txt`](../../requirements.txt)
