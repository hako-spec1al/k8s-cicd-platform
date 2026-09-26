import os

from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI(title="K8s CI/CD Platform API", version=os.getenv("APP_VERSION", "dev"))

Instrumentator().instrument(app).expose(app, endpoint="./metrics")

@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/ready")
def ready() -> dict[str, str]:
    return {"status": "ready"}


@app.get("/version")
def version() -> dict[str, str]:
    return {"version": app.version}
