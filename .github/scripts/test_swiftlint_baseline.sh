#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
materializer="$repo_root/.github/scripts/materialize_swiftlint_baseline.sh"
[[ -f "$materializer" ]] || { echo "Missing SwiftLint baseline materializer: $materializer" >&2; exit 127; }

fixture_dir="$(mktemp -d "${TMPDIR:-/tmp}/eksilik-swiftlint-baseline.XXXXXX")"
trap 'rm -rf "$fixture_dir"' EXIT
mkdir -p "$fixture_dir/repository/Core"

printf '%s\n' '[{"violation":{"location":{"file":"file:///__REPOSITORY_ROOT__/Core/Test.swift"}}}]' \
    > "$fixture_dir/canonical.json"

bash "$materializer" \
    "$fixture_dir/canonical.json" \
    "$fixture_dir/runtime.json" \
    "$fixture_dir/repository"

expected="file://$fixture_dir/repository/Core/Test.swift"
[[ "$(jq -r '.[0].violation.location.file' "$fixture_dir/runtime.json")" == "$expected" ]]
grep -Fq '__REPOSITORY_ROOT__' "$fixture_dir/canonical.json"
if grep -Fq '__REPOSITORY_ROOT__' "$fixture_dir/runtime.json"; then
    echo "Runtime baseline still contains the repository placeholder" >&2
    exit 1
fi

echo "PASS: portable SwiftLint baseline"
