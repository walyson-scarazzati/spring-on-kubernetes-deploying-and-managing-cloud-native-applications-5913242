#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Work around unreliable DNS forwarding from Docker's embedded resolver
# inside Docker-in-Docker devcontainers (e.g. GitHub Codespaces), which
# causes nodes to fail resolving external registries like ghcr.io.
printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > /tmp/kind-resolv.conf

kind create cluster --config config.yaml