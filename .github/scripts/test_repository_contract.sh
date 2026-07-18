#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
checker="$repo_root/.github/scripts/check_repository_contract.sh"
[[ -f "$checker" ]] || { echo "Missing policy implementation: $checker" >&2; exit 127; }
output="$(mktemp "${TMPDIR:-/tmp}/eksilik-repository-contract.XXXXXX")"
trap 'rm -f "$output"' EXIT

bash "$checker" "$repo_root" > "$output"
grep -Fq 'PASS: repository excellence contract' "$output"

echo "PASS: repository contract test"
