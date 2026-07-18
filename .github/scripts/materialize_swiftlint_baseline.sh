#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <canonical-baseline.json> <runtime-baseline.json> <repository-root>" >&2
    exit 64
fi

canonical_path="$1"
runtime_path="$2"
repository_root="$(cd "$3" && pwd)"
placeholder="file:///__REPOSITORY_ROOT__"
replacement="file://$repository_root"

[[ -s "$canonical_path" ]] || { echo "Canonical SwiftLint baseline is missing: $canonical_path" >&2; exit 1; }
[[ "$canonical_path" != "$runtime_path" ]] || { echo "Input and output baseline paths must differ" >&2; exit 64; }
jq -e --arg placeholder "$placeholder" \
    'type == "array" and any(.. | strings; contains($placeholder))' \
    "$canonical_path" >/dev/null \
    || { echo "Canonical SwiftLint baseline is invalid or has no repository placeholder" >&2; exit 1; }

mkdir -p "$(dirname "$runtime_path")"
temporary_path="$(mktemp "${runtime_path}.XXXXXX")"
trap 'rm -f "$temporary_path"' EXIT

jq --arg placeholder "$placeholder" --arg replacement "$replacement" '
    walk(if type == "string" then gsub($placeholder; $replacement) else . end)
' "$canonical_path" > "$temporary_path"

if grep -Fq '__REPOSITORY_ROOT__' "$temporary_path"; then
    echo "Materialized SwiftLint baseline still contains a repository placeholder" >&2
    exit 1
fi

mv "$temporary_path" "$runtime_path"
echo "Materialized SwiftLint baseline: $runtime_path"
