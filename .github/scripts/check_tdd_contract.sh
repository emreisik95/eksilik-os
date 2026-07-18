#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 <base-sha> <head-sha> [repository-root]" >&2
    exit 64
fi

base_sha="$1"
head_sha="$2"
repo_root="${3:-$(git rev-parse --show-toplevel)}"

git -C "$repo_root" cat-file -e "$base_sha^{commit}" 2>/dev/null \
    || { echo "Unknown base commit: $base_sha" >&2; exit 1; }
git -C "$repo_root" cat-file -e "$head_sha^{commit}" 2>/dev/null \
    || { echo "Unknown head commit: $head_sha" >&2; exit 1; }

production_files="$(
    git -C "$repo_root" diff --name-only --diff-filter=ACDMRTUXB "$base_sha...$head_sha" \
        | grep -E '^(App|Core|Models|Services|ViewModels|Views|EksilikWidget)/.*\.swift$' \
        || true
)"
test_files="$(
    git -C "$repo_root" diff --name-only --diff-filter=ACMRTUXB "$base_sha...$head_sha" \
        | grep -E '^EksilikTests/.*\.swift$' \
        || true
)"

if [[ -z "$production_files" ]]; then
    echo "TDD contract passed: no production Swift changes"
    exit 0
fi

if [[ -z "$test_files" ]]; then
    echo "Production Swift changed without an EksilikTests change:" >&2
    printf '%s\n' "$production_files" >&2
    echo "Add a failing regression/behavior test first, then make it green." >&2
    exit 1
fi

echo "TDD contract passed: production and test changes move together"
