# Incident Report: k3d Cluster Failed to Start with Missing Docker RWLayer

- **Date recorded:** 2026-10-12
- **Environment:** GitHub Codespaces, Docker-in-Docker, k3d
- **Cluster:** `platform`
- **Status:** Resolved by recreating the cluster; underlying Docker storage cause undetermined.

## Symptoms

`k3d cluster start platform` failed while reading the load balancer configuration and
while writing k3d startup scripts into the server container. Docker returned:

```text
RWLayer of container <container-id> is unexpectedly nil
```

The `server-0`, `agent-0`, and `serverlb` containers were stopped. `docker inspect`
showed `GraphDriver=null` for those containers, and `docker system df` failed with
`rw layer snapshot not found`. The Docker data filesystem had 17 GB available, so
the observed failure was not caused by a full filesystem.

## Cause

The immediate failure was that Docker could not access a writable layer/snapshot for
the existing k3d containers. Without that layer, k3d could not read or write files in
the containers to start the cluster.

The evidence does not identify why the layer/snapshot became unavailable. Treat
container metadata and snapshot storage becoming inconsistent as a possible
explanation, not a confirmed root cause. There was no evidence that the k3d cluster
configuration itself caused this Docker runtime error.

## Impact

The existing `platform` cluster could not be started. Recreating it removed its
Kubernetes state and may have deleted persistent-volume data. The cluster was
recreated only after confirming that it could be discarded.

## Resolution

Ran [`setup-codespaces.sh`](../../setup-codespaces.sh), which deleted the failed
cluster and created a new one. The script also bootstraps Argo CD, monitoring, and
the platform API. Verification after recovery showed:

- Both k3d nodes (`server-0` and `agent-0`) were `Ready`.
- The load balancer and both node containers were running.
- Argo CD and Grafana deployments rolled out successfully, and Prometheus became
  ready.
- The platform API pod became `1/1 Running`.

The first deletion attempt reported the same RWLayer error while inspecting the old
load balancer, but k3d completed cluster deletion and successfully created the new
cluster afterward.

## Follow-up

- Before deleting or recreating a cluster, confirm that its workloads and
  persistent-volume data can be discarded or have been backed up.
- If the error returns, capture Docker daemon and container diagnostics before
  deleting the affected containers. Check `docker info`, `docker inspect` for the
  affected containers (including `GraphDriver`), `docker system df`, and available
  disk space. Do not assume that restarting k3d alone will repair a missing snapshot.
- If the Docker storage problem persists, use the supported Codespaces or
  Docker-in-Docker lifecycle controls to restart/rebuild the environment, following
  its data-retention guidance. Avoid broad Docker prune/volume-removal commands
  unless their impact is understood.
- For routine cluster operations and data-loss warnings, see the
  [operations runbook](../runbooks/operational-commands.md).
