# Project Roadmap

## Goal

Build a production-oriented Kubernetes CI/CD platform for a FastAPI service, covering automated testing, container delivery, GitOps deployment, observability, and operational documentation.

## Phase Status

| Phase | Status | Outcome |
| --- | --- | --- |
| 1. API foundation | Complete | FastAPI provides `/health`, `/ready`, `/version`, and unit tests. |
| 2. Containerization | Complete | Python 3.11 image runs as a non-root user. |
| 3. CI | Complete | GitHub Actions runs tests, builds and pushes to GHCR, and opens a deployment PR. Trivy scanning is not present in the current workflow and remains a follow-up. |
| 4. Kubernetes | Complete | Workload runs on k3d with probes, resource limits, Ingress, and a verified rolling update. |
| 5. Helm | Complete | Chart provides shared defaults and dev/staging values. |
| 6. GitOps | Complete | Argo CD Application enables automated sync, pruning, and self-healing. |
| 7. CI/CD | Complete | SHA-tagged images and automated Helm-value updates through deployment PRs. Project milestone: `v0.7.0`. |
| 8. Observability | Complete | `/metrics` is scraped by Prometheus; a four-panel Grafana dashboard is provisioned from Git; API alert rules are loaded and the Codespaces UIs were verified. Verification screenshots have been captured and will be added to the repository separately. |
| 9. Security and reliability | Not started | Add scanning, policy controls, rollback exercises, and incident runbooks. |
| 10. Portfolio and documentation | In progress | Finalize architecture materials, evidence, and operational documentation. |

## Definition of Done

- The service can be run locally and its API can be tested using the documented workflow.
- CI tests changes before image publication; images are traceable by commit SHA.
- Helm and Argo CD manage Kubernetes deployments with probes, resource requests/limits, and Git-based rollback.
- Prometheus scrapes application and Kubernetes metrics; Grafana provides a dashboard; at least one alert is verified through a controlled failure scenario.
- No real secrets are committed, and remaining limitations are documented.

## Scope Notes

Completion status reflects the implementation and verification history for each phase; configuration may continue to evolve on feature branches. In particular, the current CI workflow does not include Trivy even though image scanning was part of the original plan. Do not claim image scanning is implemented until that workflow step is added and verified.
