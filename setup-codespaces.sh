#!/usr/bin/env bash
set -euo pipefail

command -v curl >/dev/null
command -v sudo >/dev/null
command -v kubectl >/dev/null
command -v helm >/dev/null

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

# This deliberately recreates the dedicated Codespaces cluster.
k3d cluster delete platform >/dev/null 2>&1 || true

k3d cluster create platform \
  --servers 1 \
  --agents 1 \
  --wait \
  -p "80:80@loadbalancer" 

kubectl config use-context k3d-platform
kubectl wait --for=condition=Ready nodes --all --timeout=180s

kubectl create namespace argocd \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=300s
kubectl wait --for=condition=Established \
  crd/applications.argoproj.io --timeout=180s

# 1. CÀI ĐẶT MONITORING TRƯỚC (Để tạo các CRD như ServiceMonitor, PrometheusRule)
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/kube-prometheus-stack-values.yaml \
  --wait \
  --timeout 10m

# 2. SAU ĐÓ MỚI APPLY ARGO CD APPLICATION
kubectl apply -f argocd/application-platform-api.yaml

echo "Bootstrap complete."
kubectl get nodes
kubectl get pods -A