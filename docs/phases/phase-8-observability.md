# Phase 8: Monitoring and Observability

**Status:** Complete. Evidence screenshots have been captured and will be added to the repository separately.

## Objective

Collect application and infrastructure signals, visualize them in Grafana, create actionable alerts, and verify the setup through a controlled failure scenario.

## Completed

- FastAPI exposes `/metrics` with `prometheus-fastapi-instrumentator`; the endpoint returned HTTP 200 through port-forwarding.
- The ServiceMonitor selects the API Service in `platform-dev` and scrapes `/metrics`; the application target was verified `UP` in Prometheus.
- Prometheus loads the three API alert rules from the labeled `PrometheusRule`. They were observed as `Inactive (3)` when their conditions were not met; this is a normal state, not a discovery error.
- A four-panel Grafana dashboard covers request rate, API pod restarts, p95 latency, and 5xx rate. It is stored at [`monitoring/dashboard/dashboard.json`](../../monitoring/dashboard/dashboard.json).
- Grafana dashboard provisioning is configured through a labeled ConfigMap and the kube-prometheus-stack dashboard sidecar. Sidecar logs confirmed that it loaded the JSON and Grafana returned HTTP 200 for dashboard reload.
- The Codespaces k3d environment was verified with the FastAPI, Argo CD, Grafana, and Prometheus UIs accessible.
- The user reports that screenshots of the verification have been captured. They are not yet committed to the repository.

## Evidence Follow-up

Add the captured screenshots to the repository when ready. `Inactive (3)` only confirms that the rules are loaded and not currently firing; retain or add evidence of the controlled alert test if the screenshots do not already show it.

## Related Files

- [`app/main.py`](../../app/main.py)
- [`helm/platform-api/templates/service-monitor.yaml`](../../helm/platform-api/templates/service-monitor.yaml)
- [`helm/platform-api/templates/prometheus-rule.yaml`](../../helm/platform-api/templates/prometheus-rule.yaml)
- [`monitoring/kube-prometheus-stack-values.yaml`](../../monitoring/kube-prometheus-stack-values.yaml)
- [Resource starvation incident](../incidents/2026-09-resource-starvation.md)
