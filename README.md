# Production-like Kubernetes CI/CD Platform

[![CI](https://github.com/hako-spec1al/k8s-cicd-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/hako-spec1al/k8s-cicd-platform/actions/workflows/ci.yml)

## Project overview

Small FastAPI service used to demonstrate a production-like delivery path:

`code -> tests -> Docker image -> Kubernetes -> observability`

Current architecture:

- FastAPI API with `/health`, `/ready`, and `/version`
- Docker runtime with a non-root `appuser`
- GitHub Actions CI for pull requests and pushes to `main`
- Kubernetes manifests for local deployment with probes, resources, and rolling updates

## Phase 1: API foundation

- Added the REST endpoints `/health`, `/ready`, and `/version`.
- Added `APP_VERSION` runtime configuration.
- Added pytest unit tests.

## Phase 2: Dockerization

- Built image `k8s-cicd-platform:v0.2.0` successfully.
- Runs as non-root user `appuser` and exposes port `8000`.
- Verified all API endpoints through the published container port.

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

## Phase 3: CI

- Added GitHub Actions workflow for pull requests and pushes to `main`.
- Dependency installation and pytest run successfully in CI.
- Evidence: CI completed with `3 passed`; release tag `v0.3.0` was created on `main`.

## Phase 4: Local Kubernetes deployment

### Tools

- Docker Desktop with the Linux container engine
- `kubectl` for Kubernetes administration
- `k3d` for running k3s inside Docker
- k3d's built-in Traefik ingress controller

Install the Kubernetes tools on Windows with WinGet:

```powershell
winget install --id Kubernetes.kubectl --exact
winget install --id k3d.k3d --exact
```

Restart PowerShell after installation, then verify:

```powershell
docker version
kubectl version --client
k3d version
```

### Deploy locally

The manifest at [`k8s/platform-api.yaml`](k8s/platform-api.yaml) defines the `platform` Namespace, ConfigMap, sample Secret, Deployment, Service, and Ingress. The Deployment has two replicas, HTTP readiness/liveness probes, resource requests/limits, a rolling update strategy, and non-root security settings.

Build and create a k3d cluster with Traefik exposed on `localhost:8080`:

```powershell
docker build -t k8s-cicd-platform:v0.4.0 .
k3d cluster create platform --agents 1 -p "8080:80@loadbalancer"
k3d image import k8s-cicd-platform:v0.4.0 -c platform
kubectl config use-context k3d-platform
```

On Windows, if the generated kubeconfig uses an unreachable `host.docker.internal` API address, replace it with the published localhost port:

```powershell
$apiPort = ((docker port k3d-platform-serverlb 6443/tcp) -split ":")[-1].Trim()
kubectl config set-cluster k3d-platform --server="https://127.0.0.1:$apiPort"
```

Apply and verify the resources:

```powershell
kubectl apply -f k8s/platform-api.yaml
kubectl -n platform rollout status deployment/platform-api --timeout=180s
kubectl -n platform get pods,svc,ingress -o wide
```

Verify the API through the Service:

```powershell
kubectl -n platform port-forward svc/platform-api 8000:8000
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/ready
Invoke-RestMethod http://127.0.0.1:8000/version
```

Verify the Ingress through Traefik:

```powershell
$headers = @{ Host = "platform.local" }
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080/health -Headers $headers
```

### Phase 4 verification evidence

- [x] k3d cluster created with one server and one agent.
- [x] Both application Pods reached `Running` and `Ready`.
- [x] Deployment rollout completed successfully.
- [x] Service returned `/health`, `/ready`, and `/version` successfully.
- [x] Traefik Ingress returned HTTP `200` for `platform.local/health`.
- [x] Rolling update from image `v0.4.0` to `v0.4.1` completed successfully with two Ready replicas.
- [x] Ten consecutive health requests returned HTTP `200` after the rollout.
- [x] Deleting a Pod caused the Deployment to create a replacement Pod, and the API remained healthy.
- [x] Terminating the container process caused Kubernetes to restart it; `RESTARTS=1` was observed.

The local cluster can be removed after verification:

```powershell
k3d cluster delete platform
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

## Verification evidence

- [x] Phase 1 tests: `3 passed`.
      ![alt text](images/pytest_result.png)
- [x] Phase 2 image: `k8s-cicd-platform:v0.2.0`.
      ![alt text](images/docker_image.png)
- [x] Phase 3 CI: `3 passed`, released as `v0.3.0`.
      ![alt text](images/phase3_CI.png)
