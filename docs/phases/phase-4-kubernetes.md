# Phase 4: Kubernetes Deployment

## Objective

Run the API on local Kubernetes and practice health probes, service discovery, Ingress, rolling updates, and self-healing.

## Implementation

- Resource-specific manifests in [`k8s/`](../../k8s/) define the Namespace, ConfigMap, sample Secret, Deployment, Service, and Ingress.
- The Deployment configures replicas, resource requests/limits, readiness and liveness probes, rolling updates, and a non-root security context.
- k3d provides the local cluster; Traefik handles Ingress traffic.

## Historical Verification

The phase was tested on k3d: the rollout reached Ready, endpoints were called through the Service and Ingress, a rolling update maintained two available replicas, a deleted Pod was replaced, and a container restart was observed.

The raw manifests remain in the repository, while the GitOps deployment uses the Helm chart as its primary source. See [Phase 5](phase-5-helm.md).
