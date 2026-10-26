#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Work around unreliable DNS forwarding from Docker's embedded resolver
# inside Docker-in-Docker devcontainers (e.g. GitHub Codespaces), which
# causes nodes to fail resolving external registries like ghcr.io.
#
# The node can't use the devcontainer host's own loopback stub resolver
# (127.0.0.53 from systemd-resolved) since that's unreachable from the
# node's network namespace. Prefer whichever non-loopback nameserver the
# host itself was actually given (e.g. 168.63.129.16 on Azure-hosted
# Codespaces) over a guessed public resolver, since some devcontainer
# networks block outbound UDP:53 to public resolvers like 8.8.8.8/1.1.1.1
# entirely while still allowing the cloud provider's own internal DNS.
resolvers=$(awk '/^nameserver/ && $2 !~ /^127\./ {print $2}' /etc/resolv.conf)
if [ -z "$resolvers" ]; then
  resolvers=$'8.8.8.8\n1.1.1.1'
fi
{
  while IFS= read -r ns; do
    [ -n "$ns" ] && echo "nameserver $ns"
  done <<< "$resolvers"
} > /tmp/kind-resolv.conf

kind create cluster --config config.yaml