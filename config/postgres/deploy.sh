#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! helm repo list | grep -q 'https://cloudnative-pg.github.io/charts'; then
    helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
fi

helm upgrade --install cloudnative-pg cloudnative-pg/cloudnative-pg
echo "Waiting for operator to stabalize"
kubectl rollout status deployment/cloudnative-pg --timeout=120s
kubectl wait --for=jsonpath='{.subsets[0].addresses}' endpoints/cnpg-webhook-service --timeout=60s
kubectl apply -f config.yaml