# Phase 8: Monitoring and Observability

**Status:** In progress.

## Objective

Collect application and infrastructure signals, visualize them in Grafana, create actionable alerts, and verify the setup through a controlled failure scenario.

## Implemented in the Repository

- The `prometheus-fastapi-instrumentator` dependency and instrumentation in [`app/main.py`](../../app/main.py).
- Helm templates for `ServiceMonitor` and `PrometheusRule` resources.
- Resource limits, short retention, and temporary storage in [`monitoring/kube-prometheus-stack-values.yaml`](../../monitoring/kube-prometheus-stack-values.yaml).
- A Dev Container configured for Docker-in-Docker, kubectl/Helm, and port forwarding; `setup-codespaces.sh` bootstraps k3d, Argo CD, and monitoring.

## Remaining Work

1. Verify the actual metrics endpoint. The app currently calls `expose` with `./metrics`, while the intended endpoint and ServiceMonitor path are `/metrics`.
2. Align the ServiceMonitor selector and namespace with the chart-rendered Service. The Service has the `app.kubernetes.io/name` label and is deployed to `platform-dev`; the current ServiceMonitor selects `app: platform-api` in namespace `platform`.
3. Verify the Prometheus Operator's ServiceMonitor and PrometheusRule label and namespace selectors for the installed release.
4. Run `helm lint` and `helm template`, deploy through Argo CD, and confirm the application target is UP in Prometheus.
5. Create and verify a dashboard for request rate, 5xx rate, p95 latency, CPU/memory, and Pod restarts. There is no current evidence that a dashboard has been provisioned or tested.
6. Generate controlled errors or latency, confirm that an alert fires, and capture evidence.
7. Run the bootstrap in Codespaces and verify that the API, Argo CD, and Grafana are reachable through forwarded ports.

## Related Files

- [`app/main.py`](../../app/main.py)
- [`helm/platform-api/templates/service-monitor.yaml`](../../helm/platform-api/templates/service-monitor.yaml)
- [`helm/platform-api/templates/prometheus-rule.yaml`](../../helm/platform-api/templates/prometheus-rule.yaml)
- [`monitoring/kube-prometheus-stack-values.yaml`](../../monitoring/kube-prometheus-stack-values.yaml)
- [Resource starvation incident](../incidents/2026-09-resource-starvation.md)
