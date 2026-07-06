#!/usr/bin/env bash
# Configure git remote for pushes that include .github/workflows (requires PAT).
set -euo pipefail

if [[ -z "${BEES4EVER_GITHUB_TOKEN:-}" ]]; then
  echo "::error::Missing BEES4EVER_GITHUB_TOKEN secret. Create a fine-grained PAT with Contents (read/write) and Workflows (read/write), then: gh secret set BEES4EVER_GITHUB_TOKEN --repo bees4ever/playwright"
  exit 1
fi

git config --local --unset-all http.https://github.com/.extraheader 2>/dev/null || true
git remote set-url origin "https://x-access-token:${BEES4EVER_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
