#!/usr/bin/env bash
set -euo pipefail

if [[ ($1 == '--help') || ($1 == '-h') || ($1 == '') ]]; then
  echo "usage: $(basename "$0") {py3.13|py3.14}"
  exit 0
fi

VARIANT="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REGISTRY="$(sed -n 's/^registry: *//p' bees4ever/config.yml | tr -d ' \r')"
PW_VERSION="$(node -p "require('./packages/playwright-core/package.json').version")"
BASE="${REGISTRY}:noble-v${PW_VERSION}-${VARIANT}"

docker manifest create "${BASE}" \
  "${BASE}-amd64" \
  "${BASE}-arm64"
docker manifest push "${BASE}"

echo "Published multi-arch manifest ${BASE}"
