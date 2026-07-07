#!/usr/bin/env bash
set -e
set +x

if [[ ($1 == '--help') || ($1 == '-h') || ($1 == '') ]]; then
  echo "usage: $(basename "$0") {py3.13|py3.14} [--push|--load] (--amd64|--arm64)"
  echo
  echo "Build one platform of a bees4ever Playwright noble Docker image."
  echo "Run from repo root after 'npm ci' and 'npm run build'."
  exit 0
fi

VARIANT="$1"
PUSH_OR_LOAD="${2:---load}"
ARCH_FLAG="${3:-}"

if [[ "$VARIANT" != "py3.13" && "$VARIANT" != "py3.14" ]]; then
  echo "ERROR: unknown variant '$VARIANT'. Must be py3.13 or py3.14"
  exit 1
fi

if [[ "$PUSH_OR_LOAD" != "--push" && "$PUSH_OR_LOAD" != "--load" ]]; then
  echo "ERROR: second argument must be --push or --load"
  exit 1
fi

if [[ "$ARCH_FLAG" == "--amd64" ]]; then
  PLATFORM="linux/amd64"
  ARCH="amd64"
elif [[ "$ARCH_FLAG" == "--arm64" ]]; then
  PLATFORM="linux/arm64"
  ARCH="arm64"
else
  echo "ERROR: third argument must be --amd64 or --arm64"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DOCKERFILE="bees4ever/docker/Dockerfile.noble-${VARIANT}"
if [[ ! -f "$DOCKERFILE" ]]; then
  echo "ERROR: missing $DOCKERFILE"
  exit 1
fi

REGISTRY="$(sed -n 's/^registry: *//p' bees4ever/config.yml | tr -d ' \r')"
PW_VERSION="$(node utils/workspace.js --get-version)"
IMAGE="${REGISTRY}:noble-v${PW_VERSION}-${VARIANT}-${ARCH}"

function cleanup() {
  rm -f bees4ever/docker/playwright-core.tar.gz
}

trap cleanup EXIT

node utils/pack_package.js playwright-core bees4ever/docker/playwright-core.tar.gz

export BUILDKIT_PROGRESS=plain

echo "Building ${IMAGE} (${PLATFORM}, ${PUSH_OR_LOAD})"
docker buildx build \
  --platform "${PLATFORM}" \
  --cache-from "type=gha,scope=${VARIANT}-${ARCH}" \
  --cache-to "type=gha,mode=max,scope=${VARIANT}-${ARCH}" \
  -f "$DOCKERFILE" \
  -t "$IMAGE" \
  "$PUSH_OR_LOAD" \
  bees4ever/docker/
