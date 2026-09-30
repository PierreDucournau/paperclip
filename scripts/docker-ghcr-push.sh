#!/usr/bin/env bash
# Build + push multi-arch vers GHCR.
# Usage: docker-ghcr-push.sh [master|rpi]
# Env: GHCR_TOKEN (PAT packages:write), GHCR_USER (default: pierreducournau)

set -euo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
GHCR_USER="${GHCR_USER:-pierreducournau}"
IMAGE="ghcr.io/${GHCR_USER}/paperclip"
PLATFORMS="linux/amd64,linux/arm64"

case "$BRANCH" in
  master) TAG="master" ;;
  rpi)    TAG="rpi"    ;;
  *)
    echo "ERROR: branche non supportée '$BRANCH'. Supportées : master, rpi" >&2
    exit 1
    ;;
esac

FULL_TAG="${IMAGE}:${TAG}"
echo "==> Branch: $BRANCH  →  $FULL_TAG  ($PLATFORMS)"

[[ -z "${GHCR_TOKEN:-}" ]] && { echo "ERROR: GHCR_TOKEN manquant" >&2; exit 1; }

echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

BUILDER="paperclip-multiarch"
docker buildx inspect "$BUILDER" &>/dev/null \
  || docker buildx create --name "$BUILDER" --driver docker-container
docker buildx use "$BUILDER"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
docker buildx build \
  --platform "$PLATFORMS" \
  --push \
  -t "$FULL_TAG" \
  "$REPO_ROOT"

echo "==> Done: $FULL_TAG"
