#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Installing kind"
../config/kind/deploy.sh
echo "Waiting for the node to be ready"
kubectl wait --for=condition=Ready node --all --timeout=120s

echo "Installing ingress"
../config/ingress/deploy.sh
echo "Waiting for ingress-nginx to become available"
kubectl wait --for=condition=Available deployment --all -n ingress-nginx --timeout=180s

echo "Installing monitoring"
../config/monitoring/deploy.sh
echo "Waiting for monitoring to become available"
kubectl wait --for=condition=Available deployment --all -n monitoring --timeout=300s

echo "Installing postgres"
../config/postgres/deploy.sh
echo "Waiting for the postgres cluster to become healthy"
kubectl wait --for=condition=Ready pods -l cnpg.io/cluster=localdb,cnpg.io/podRole=instance -n postgres --timeout=600s

./populate-db.sh

