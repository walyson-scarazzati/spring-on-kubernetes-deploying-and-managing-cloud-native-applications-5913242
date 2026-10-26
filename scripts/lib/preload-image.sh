# Pulls an image on the host (where DNS/network normally works, even
# when a kind node's network namespace can't resolve external
# registries - see config/kind/deploy.sh) and imports it directly into
# every node of the given kind cluster, so later kubectl applies never
# block on a live in-cluster pull.
#
# Any failure here is non-fatal: if preloading doesn't work, Kubernetes
# just falls back to its own pull path as if this had never run.
preload_image() {
  local image="$1" cluster="${2:-local}"
  local tar
  tar="$(mktemp -t preload-image-XXXXXX.tar)"

  echo "Preloading $image into kind cluster '$cluster'..."

  if ! docker pull --platform linux/amd64 "$image"; then
    echo "  could not pull $image on the host, skipping preload (kubelet will retry the pull itself)"
    rm -f "$tar"
    return 0
  fi

  docker save "$image" -o "$tar"

  for node in $(kind get nodes --name "$cluster" 2>/dev/null); do
    if ! docker exec -i "$node" ctr --namespace=k8s.io images import \
        --platform linux/amd64 --digests --snapshotter=overlayfs - < "$tar"; then
      echo "  failed to import $image into node $node, continuing anyway"
    fi
  done

  rm -f "$tar"
}
