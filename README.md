# Production-like Kubernetes CI/CD Platform

## Project overview

This phase focuses only on packaging the Phase 1 API as a Docker image and running it locally. CI/CD, Kubernetes, Helm, and monitoring will be added in later phases.

### Included

- FastAPI API with `/health`, `/ready`, and `/version`
- `APP_VERSION` configuration through an environment variable
- Unit tests with pytest
- Local development instructions

## Phase 2: Dockerize

The image runs the API as a non-root user and exposes port `8000`.

### Verified locally

- Image `k8s-cicd-platform:v0.2.0` builds successfully.
- Container runs with user `appuser`.
- `/health` returns `{"status":"ok"}`.
- `/ready` returns `{"status":"ready"}`.
- `/version` returns `{"version":"v0.2.0"}` when configured with `APP_VERSION=v0.2.0`.

Build the image:

```powershell
docker build -t k8s-cicd-platform:v0.2.0 .
```

Run the container:

```powershell
docker run --rm -p 8000:8000 -e APP_VERSION=v0.2.0 k8s-cicd-platform:v0.2.0
```

Verify the containerized API:

```powershell
Invoke-RestMethod http://localhost:8000/health
Invoke-RestMethod http://localhost:8000/ready
Invoke-RestMethod http://localhost:8000/version
```

## Run locally

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest
uvicorn app.main:app --reload
```

Open `http://localhost:8000/docs` for the API documentation.

## Phase 2 checklist

- [x] Docker image builds successfully.
- [x] Container starts successfully.
- [x] API endpoints work through the published port.
- [x] Container runs as a non-root user.
- [x] `APP_VERSION` is configurable at runtime.

## Next phase

Phase 3 will add GitHub Actions CI. It should begin only after the Phase 2 checklist is complete and committed.
