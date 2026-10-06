# Incident Report: Local Monitoring Resource Starvation

- **Date recorded:** 2026-09-27
- **Environment:** Windows, Docker Desktop/WSL, k3d
- **Status:** Mitigation identified; the Codespaces environment has not yet been verified as operational.

## Symptoms

- Host CPU utilization reached approximately 200–300%, and the development environment became unresponsive.
- The Kubernetes API server reported TLS handshake timeouts.
- Prometheus Operator and Grafana entered `CrashLoopBackOff`.
- Docker Desktop showed approximately 3.6 GB of memory allocated to the WSL VM. High cumulative disk reads were also observed, but that counter alone does not prove that swapping occurred.

## Root Cause

The resources available to Docker Desktop/WSL were insufficient for k3d, Argo CD, and `kube-prometheus-stack` running concurrently. The monitoring stack added workloads, Prometheus TSDB activity, and supporting components; CPU and memory pressure destabilized the Kubernetes API and Pods.

This explanation is consistent with the observed symptoms and resource limits. No memory profile or kernel-level diagnostics were collected to identify a single process as the definitive cause.

## Resolution and Mitigation

1. Stop or uninstall the monitoring release when host recovery is necessary. Verify the Helm release name and namespace before uninstalling.
2. Use values that constrain requests and limits, run one replica, shorten retention, disable unnecessary default rules, and use temporary storage for the demo. The current configuration is [`monitoring/kube-prometheus-stack-values.yaml`](../../monitoring/kube-prometheus-stack-values.yaml).
3. Move the Phase 8 lab to a 4-core/8-GB GitHub Codespace using Docker-in-Docker and k3d to increase available resources.
4. In Codespaces, monitor `kubectl get pods -A`, cluster events, and resource usage before increasing workload.

**Closure criteria:** The Codespaces cluster starts reliably; Argo CD and monitoring workloads become Ready; and Prometheus/Grafana do not suffer repeated OOM kills or restarts. Keep this incident open until those checks have supporting evidence.

## Lessons Learned

- Budget CPU and memory across the entire cluster, not only for Prometheus.
- Do not infer swapping from cumulative disk reads; use memory-pressure/swap metrics or system logs.
- Start with short scrape intervals and retention, then increase them based on observed resource usage.
