#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <xccov-report.json> <coverage-baseline.json>" >&2
    exit 64
fi

report_path="$1"
baseline_path="$2"

[[ -s "$report_path" ]] || { echo "Coverage report is missing or empty: $report_path" >&2; exit 1; }
[[ -s "$baseline_path" ]] || { echo "Coverage baseline is missing or empty: $baseline_path" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required to evaluate coverage" >&2; exit 1; }

target="$(jq -er '.target | strings | select(length > 0)' "$baseline_path")"
minimum="$(jq -er '.minimumLineCoverage | numbers' "$baseline_path")"

if ! coverage_fraction="$(jq -er --arg target "$target" '.targets[] | select(.name == $target) | .lineCoverage' "$report_path" | head -n 1)"; then
    echo "Coverage target not found: $target" >&2
    echo "Available targets:" >&2
    jq -r '.targets[]?.name // empty' "$report_path" >&2
    exit 1
fi

coverage="$(awk -v value="$coverage_fraction" 'BEGIN { printf "%.4f", value * 100 }')"
minimum_formatted="$(awk -v value="$minimum" 'BEGIN { printf "%.4f", value }')"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf 'line_coverage=%s\n' "$coverage" >> "$GITHUB_OUTPUT"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
        echo "### Code coverage"
        echo
        echo "- Target: \`$target\`"
        echo "- Line coverage: **$coverage%**"
        echo "- Required baseline: **$minimum_formatted%**"
    } >> "$GITHUB_STEP_SUMMARY"
fi

if ! awk -v actual="$coverage" -v required="$minimum_formatted" 'BEGIN { exit(actual + 0.0000001 >= required ? 0 : 1) }'; then
    echo "Coverage gate failed: $coverage% < $minimum_formatted%" >&2
    exit 1
fi

echo "Coverage gate passed: $coverage% >= $minimum_formatted%"

