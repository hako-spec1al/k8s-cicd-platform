#!/usr/bin/env bash
set -euo pipefail

command -v curl >/dev/null
command -v sudo >/dev/null
command -v kubectl >/dev/null
command -v helm >/dev/null

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this script as the Codespaces user, not with sudo." >&2
  exit 1
fi

export KUBECONFIG="${KUBECONFIG:-${HOME}/.kube/config}"
mkdir -p "$(dirname "$KUBECONFIG")"

K3D_API_PORT="${K3D_API_PORT:-6443}"

case "$(uname -m)" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v k3d >/dev/null; then
  curl -fsSL \
    "https://github.com/k3d-io/k3d/releases/latest/download/k3d-linux-${ARCH}" \
    -o "$TMP_DIR/k3d"
  sudo install -m 0755 "$TMP_DIR/k3d" /usr/local/bin/k3d
fi

if ! command -v yq >/dev/null; then
  curl -fsSL \
    "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" \
    -o "$TMP_DIR/yq"
  sudo install -m 0755 "$TMP_DIR/yq" /usr/local/bin/yq
fi

docker info >/dev/null

# Recreate the dedicated Codespaces cluster from a clean state.
k3d cluster delete platform || true

k3d cluster create platform \
  --servers 1 \
  --agents 1 \
  --api-port "127.0.0.1:${K3D_API_PORT}" \
  -p "80:80@loadbalancer" \
  --wait \
  --timeout 180s

k3d kubeconfig merge platform \
  --kubeconfig-switch-context \
  --output "$KUBECONFIG"
chmod 600 "$KUBECONFIG"
kubectl config use-context k3d-platform
kubectl config set-cluster k3d-platform \
  --server="https://127.0.0.1:${K3D_API_PORT}"
kubectl get nodes
kubectl wait --for=condition=Ready nodes --all --timeout=180s
kubectl get nodes

kubectl create namespace argocd \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=300s
kubectl wait --for=condition=Established \
  crd/applications.argoproj.io --timeout=180s

# 1. CÀI ĐẶT MONITORING TRƯỚC (Để tạo các CRD như ServiceMonitor, PrometheusRule)
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts \
  --force-update
helm repo update

helm upgrade --install monitoring \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/kube-prometheus-stack-values.yaml \
  --wait \
  --timeout 10m

# Provision the version-controlled dashboard through the Grafana sidecar.
kubectl create configmap platform-api-dashboard \
  --namespace monitoring \
  --from-file=dashboard.json=monitoring/dashboard/dashboard.json \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label configmap platform-api-dashboard \
  --namespace monitoring grafana_dashboard=1 --overwrite

# 2. SAU ĐÓ MỚI APPLY ARGO CD APPLICATION
kubectl apply -f argocd/application-platform-api.yaml

echo "Bootstrap complete."
kubectl get nodes
kubectl get pods -A