# Production-like Kubernetes CI/CD Platform

## Phase 1: Application foundation

This phase focuses only on making a small API understandable, testable, and runnable locally. Containerization, CI/CD, Kubernetes, Helm, and monitoring will be added in later phases.

### Included

- FastAPI API with `/health`, `/ready`, and `/version`
- `APP_VERSION` configuration through an environment variable
- Unit tests with pytest
- Local development instructions

## Run locally

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest
uvicorn app.main:app --reload
```

Open `http://localhost:8000/docs` for the API documentation.

## Phase 1 checklist

- [x] API starts locally.
- [x] `/health` returns an OK status.
- [x] `/ready` returns a ready status.
- [x] `/version` returns the configured version.
- [x] Automated tests cover the three endpoints.
- [ ] Add linting and formatting checks.
- [ ] Add structured application logging.
- [ ] Add graceful shutdown handling if the app gains background resources.

## Next phase

Phase 2 will package this application as a Docker image. It should begin only after the Phase 1 checklist is complete and committed.
