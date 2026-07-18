#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
checker="$repo_root/.github/scripts/check_quality_baseline_changes.sh"
[[ -f "$checker" ]] || { echo "Missing quality baseline checker: $checker" >&2; exit 127; }

fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/eksilik-quality-baseline.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

write_baselines() {
    local repository="$1"
    local coverage="$2"
    local lint_entries="$3"
    mkdir -p "$repository/.github"
    printf '{"target":"EksilikApp.app","minimumLineCoverage":%s}\n' "$coverage" \
        > "$repository/.github/coverage-baseline.json"
    printf '%s\n' "$lint_entries" > "$repository/.swiftlint-baseline.json"
}

initialize_fixture() {
    local repository="$1"
    git init -q "$repository"
    git -C "$repository" config user.email test@example.com
    git -C "$repository" config user.name "Quality Test"
    write_baselines "$repository" 20.0 '[
      {"violation":{"ruleIdentifier":"line_length","reason":"A","location":{"file":"file:///__REPOSITORY_ROOT__/A.swift"}},"text":"A"},
      {"violation":{"ruleIdentifier":"file_length","reason":"B","location":{"file":"file:///__REPOSITORY_ROOT__/B.swift"}},"text":"B"}
    ]'
    git -C "$repository" add .
    git -C "$repository" commit -qm base
}

good_repo="$fixture_root/good"
initialize_fixture "$good_repo"
good_base="$(git -C "$good_repo" rev-parse HEAD)"
write_baselines "$good_repo" 21.0 '[
  {"violation":{"ruleIdentifier":"line_length","reason":"A","location":{"file":"file:///__REPOSITORY_ROOT__/A.swift"}},"text":"A"}
]'
git -C "$good_repo" add .
git -C "$good_repo" commit -qm improve
bash "$checker" "$good_base" "$(git -C "$good_repo" rev-parse HEAD)" "$good_repo"

coverage_repo="$fixture_root/lower-coverage"
initialize_fixture "$coverage_repo"
coverage_base="$(git -C "$coverage_repo" rev-parse HEAD)"
write_baselines "$coverage_repo" 19.9 '[
  {"violation":{"ruleIdentifier":"line_length","reason":"A","location":{"file":"file:///__REPOSITORY_ROOT__/A.swift"}},"text":"A"},
  {"violation":{"ruleIdentifier":"file_length","reason":"B","location":{"file":"file:///__REPOSITORY_ROOT__/B.swift"}},"text":"B"}
]'
git -C "$coverage_repo" add .
git -C "$coverage_repo" commit -qm lower
if bash "$checker" "$coverage_base" "$(git -C "$coverage_repo" rev-parse HEAD)" "$coverage_repo" \
    > "$fixture_root/lower-coverage.out" 2>&1; then
    echo "Expected a lower coverage baseline to fail" >&2
    exit 1
fi
grep -Fq 'Coverage baseline may not decrease' "$fixture_root/lower-coverage.out"

lint_repo="$fixture_root/add-lint"
initialize_fixture "$lint_repo"
lint_base="$(git -C "$lint_repo" rev-parse HEAD)"
write_baselines "$lint_repo" 20.0 '[
  {"violation":{"ruleIdentifier":"line_length","reason":"A","location":{"file":"file:///__REPOSITORY_ROOT__/A.swift"}},"text":"A"},
  {"violation":{"ruleIdentifier":"file_length","reason":"B","location":{"file":"file:///__REPOSITORY_ROOT__/B.swift"}},"text":"B"},
  {"violation":{"ruleIdentifier":"type_body_length","reason":"C","location":{"file":"file:///__REPOSITORY_ROOT__/C.swift"}},"text":"C"}
]'
git -C "$lint_repo" add .
git -C "$lint_repo" commit -qm add-lint
if bash "$checker" "$lint_base" "$(git -C "$lint_repo" rev-parse HEAD)" "$lint_repo" \
    > "$fixture_root/add-lint.out" 2>&1; then
    echo "Expected new lint debt in the baseline to fail" >&2
    exit 1
fi
grep -Fq 'SwiftLint baseline may only shrink' "$fixture_root/add-lint.out"

echo "PASS: immutable quality baseline contract"
