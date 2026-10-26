#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
source ../../scripts/lib/preload-image.sh

if ! helm repo list | grep -q 'https://cloudnative-pg.github.io/charts'; then
    helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
fi

helm upgrade --install cloudnative-pg cloudnative-pg/cloudnative-pg

# Preload the operator image and the Postgres instance image (pinned in
# config.yaml) before anything is scheduled, so neither depends on a
# live in-cluster registry pull once the deployment/Cluster come up.
operator_image=$(kubectl get deployment/cloudnative-pg -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
[ -n "$operator_image" ] && preload_image "$operator_image"

postgres_image=$(grep '^\s*imageName:' config.yaml | awk '{print $2}' | head -1)
[ -n "$postgres_image" ] && preload_image "$postgres_image"

echo "Waiting for operator to stabalize"
kubectl rollout status deployment/cloudnative-pg --timeout=300s
kubectl wait --for=jsonpath='{.subsets[0].addresses}' endpoints/cnpg-webhook-service --timeout=120s
kubectl apply -f config.yaml