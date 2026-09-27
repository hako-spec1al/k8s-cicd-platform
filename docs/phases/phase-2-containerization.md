# Phase 2: Containerization

## Objective

Package the FastAPI service into a reproducible container that runs as a non-root user.

## Implementation

- Uses the `python:3.11-slim` base image.
- Installs dependencies from `requirements.txt`, copies the `app` package, and runs Uvicorn on port `8000`.
- Creates and switches to the `appuser` account before starting the service.
- `.dockerignore` excludes the virtual environment, caches, and `.env`.

## Build and Run

```bash
docker build -t k8s-cicd-platform:local .
docker run --rm -p 8000:8000 -e APP_VERSION=local k8s-cicd-platform:local
```

From another terminal, check `/health`, `/ready`, and `/version`. The current Dockerfile is single-stage and does not define a Docker `HEALTHCHECK`.

## Related Files

- [`Dockerfile`](../../Dockerfile)
- [`.dockerignore`](../../.dockerignore)
