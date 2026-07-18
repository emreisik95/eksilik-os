#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
checker="$repo_root/.github/scripts/check_coverage.sh"
[[ -f "$checker" ]] || { echo "Missing policy implementation: $checker" >&2; exit 127; }
fixture_dir="$(mktemp -d "${TMPDIR:-/tmp}/eksilik-coverage-test.XXXXXX")"
trap 'rm -rf "$fixture_dir"' EXIT

baseline="$fixture_dir/baseline.json"
passing_report="$fixture_dir/passing.json"
failing_report="$fixture_dir/failing.json"
missing_target_report="$fixture_dir/missing-target.json"

printf '%s\n' '{"target":"EksilikApp.app","minimumLineCoverage":42.5}' > "$baseline"
printf '%s\n' '{"targets":[{"name":"EksilikApp.app","lineCoverage":0.425}]}' > "$passing_report"
printf '%s\n' '{"targets":[{"name":"EksilikApp.app","lineCoverage":0.424}]}' > "$failing_report"
printf '%s\n' '{"targets":[{"name":"EksilikWidget.appex","lineCoverage":0.99}]}' > "$missing_target_report"

bash "$checker" "$passing_report" "$baseline" > "$fixture_dir/passing.out"
grep -Fq 'Coverage gate passed: 42.5000% >= 42.5000%' "$fixture_dir/passing.out"

if bash "$checker" "$failing_report" "$baseline" > "$fixture_dir/failing.out" 2>&1; then
    echo "Expected coverage below the baseline to fail" >&2
    exit 1
fi
grep -Fq 'Coverage gate failed: 42.4000% < 42.5000%' "$fixture_dir/failing.out"

if bash "$checker" "$missing_target_report" "$baseline" > "$fixture_dir/missing.out" 2>&1; then
    echo "Expected a missing app target to fail" >&2
    exit 1
fi
grep -Fq 'Coverage target not found: EksilikApp.app' "$fixture_dir/missing.out"

echo "PASS: coverage gate contract"
