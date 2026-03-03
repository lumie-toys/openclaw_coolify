#!/usr/bin/env bash
# Build openclaw Docker images locally.
#
# Usage:
#   ./scripts/build.sh                  # build both base + final
#   ./scripts/build.sh base             # build base only
#   ./scripts/build.sh final            # build final only (requires base)
#   ./scripts/build.sh browser          # build browser sidecar only
#   # Source is read from local ./openclaw submodule

set -euo pipefail

BASE_TAG="openclaw-base:local"
FINAL_TAG="openclaw:local"
BROWSER_TAG="openclaw-browser:local"
TARGET="${1:-all}"

build_base() {
  echo "==> Building base image (source: ./openclaw)..."
  docker build \
    -f Dockerfile.base \
    -t "${BASE_TAG}" \
    .
  echo "==> Base image built: ${BASE_TAG}"
}

build_final() {
  echo "==> Building final image..."
  docker build \
    -f Dockerfile \
    --build-arg "BASE_IMAGE=${BASE_TAG}" \
    -t "${FINAL_TAG}" \
    .
  echo "==> Final image built: ${FINAL_TAG}"
}

build_browser() {
  echo "==> Building browser sidecar image..."
  docker build \
    -f Dockerfile.browser \
    -t "${BROWSER_TAG}" \
    .
  echo "==> Browser image built: ${BROWSER_TAG}"
}

case "${TARGET}" in
  base)
    build_base
    ;;
  final)
    build_final
    ;;
  browser)
    build_browser
    ;;
  all)
    build_base
    build_final
    build_browser
    ;;
  *)
    echo "Usage: $0 [base|final|browser|all]"
    exit 1
    ;;
esac

echo ""
echo "Done. Run with:"
echo "  docker run -e OPENCLAW_GATEWAY_TOKEN=\$(openssl rand -hex 32) -e ANTHROPIC_API_KEY=sk-... -e AUTH_PASSWORD=secret -p 8080:8080 ${FINAL_TAG}"
