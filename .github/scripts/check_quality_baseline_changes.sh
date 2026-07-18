#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <base-sha> <head-sha> <repository-root>" >&2
    exit 64
fi

base_sha="$1"
head_sha="$2"
repo_root="$3"

git -C "$repo_root" cat-file -e "$base_sha^{commit}" 2>/dev/null \
    || { echo "Unknown base commit: $base_sha" >&2; exit 1; }
git -C "$repo_root" cat-file -e "$head_sha^{commit}" 2>/dev/null \
    || { echo "Unknown head commit: $head_sha" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required to compare quality baselines" >&2; exit 1; }

work_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/quality-baseline.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

extract_required() {
    local revision="$1"
    local path="$2"
    local destination="$3"
    git -C "$repo_root" show "${revision}:${path}" > "$destination" 2>/dev/null \
        || { echo "Required quality baseline is missing at $revision: $path" >&2; exit 1; }
}

coverage_path=".github/coverage-baseline.json"
head_coverage="$work_dir/head-coverage.json"
extract_required "$head_sha" "$coverage_path" "$head_coverage"

if git -C "$repo_root" cat-file -e "${base_sha}:${coverage_path}" 2>/dev/null; then
    base_coverage="$work_dir/base-coverage.json"
    extract_required "$base_sha" "$coverage_path" "$base_coverage"
    base_target="$(jq -er '.target | strings | select(length > 0)' "$base_coverage")"
    head_target="$(jq -er '.target | strings | select(length > 0)' "$head_coverage")"
    [[ "$head_target" == "$base_target" ]] \
        || { echo "Coverage target may not change: $base_target -> $head_target" >&2; exit 1; }
    base_minimum="$(jq -er '.minimumLineCoverage | numbers' "$base_coverage")"
    head_minimum="$(jq -er '.minimumLineCoverage | numbers' "$head_coverage")"
    if ! awk -v base="$base_minimum" -v head="$head_minimum" \
        'BEGIN { exit(head + 0.0000001 >= base ? 0 : 1) }'; then
        echo "Coverage baseline may not decrease: $base_minimum -> $head_minimum" >&2
        exit 1
    fi
else
    echo "Coverage baseline initialized in this change"
fi

lint_path=".swiftlint-baseline.json"
head_lint="$work_dir/head-swiftlint.json"
extract_required "$head_sha" "$lint_path" "$head_lint"
jq -e 'type == "array"' "$head_lint" >/dev/null \
    || { echo "SwiftLint baseline must be a JSON array" >&2; exit 1; }

baseline_counts() {
    jq -c '
        group_by([
            .violation.ruleIdentifier,
            .violation.location.file,
            .text,
            .violation.reason
        ])
        | map({
            key: (.[0] | [
                .violation.ruleIdentifier,
                .violation.location.file,
                .text,
                .violation.reason
            ]),
            count: length
        })
    ' "$1"
}

if git -C "$repo_root" cat-file -e "${base_sha}:${lint_path}" 2>/dev/null; then
    base_lint="$work_dir/base-swiftlint.json"
    base_counts="$work_dir/base-counts.json"
    head_counts="$work_dir/head-counts.json"
    additions="$work_dir/additions.json"
    extract_required "$base_sha" "$lint_path" "$base_lint"
    jq -e 'type == "array"' "$base_lint" >/dev/null \
        || { echo "Base SwiftLint baseline is not a JSON array" >&2; exit 1; }
    baseline_counts "$base_lint" > "$base_counts"
    baseline_counts "$head_lint" > "$head_counts"

    jq -n --slurpfile old "$base_counts" --slurpfile new "$head_counts" '
        [
            $new[0][] as $candidate
            | (($old[0] | map(select(.key == $candidate.key)) | first | .count) // 0) as $previous
            | select($candidate.count > $previous)
            | $candidate + {previousCount: $previous}
        ]
    ' > "$additions"

    if [[ "$(jq 'length' "$additions")" -gt 0 ]]; then
        echo "SwiftLint baseline may only shrink; new lint debt was added:" >&2
        jq -r '.[] | "- \(.key[1]) [\(.key[0])]: \(.key[3])"' "$additions" >&2
        exit 1
    fi
else
    echo "SwiftLint baseline initialized in this change"
fi

echo "Quality baselines are monotonic"
