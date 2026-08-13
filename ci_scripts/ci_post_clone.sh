#!/usr/bin/env bash
set -euo pipefail

repo_root="${CI_PRIMARY_REPOSITORY_PATH:-$(git rev-parse --show-toplevel)}"
bash "$repo_root/.github/scripts/bootstrap_xcode_cloud.sh" "$repo_root"
