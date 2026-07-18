#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(git rev-parse --show-toplevel)}"
cd "$repo_root"

fail() {
    echo "Repository contract failed: $1" >&2
    exit 1
}

required_files=(
    .github/CODEOWNERS
    .github/coverage-baseline.json
    .github/pull_request_template.md
    .github/ISSUE_TEMPLATE/bug_report.yml
    .github/ISSUE_TEMPLATE/feature_request.yml
    .github/ISSUE_TEMPLATE/config.yml
    .github/workflows/build.yml
    .github/workflows/codeql.yml
    .github/workflows/device-build.yml
    .github/workflows/app-store-release.yml
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    README.md
    SECURITY.md
    SUPPORT.md
)

for path in "${required_files[@]}"; do
    [[ -s "$path" ]] || fail "$path is missing or empty"
done

if grep -Rqs 'pull_request_target' .github/workflows; then
    fail "pull_request_target is forbidden"
fi

while IFS= read -r workflow; do
    grep -q '^permissions:' "$workflow" || fail "$workflow must declare top-level permissions"
done < <(find .github/workflows -type f -name '*.yml' -print | sort)

while IFS= read -r reference; do
    case "$reference" in
        ./*) ;;
        docker://*@sha256:????????????????????????????????????????????????????????????????) ;;
        *@????????????????????????????????????????) ;;
        *) fail "action reference is not pinned to an immutable digest: $reference" ;;
    esac
done < <(grep -RhoE 'uses:[[:space:]]*[^[:space:]]+' .github/workflows | awk '{print $2}')

checkout_count="$(grep -RhcE 'uses:[[:space:]]*actions/checkout@' .github/workflows | awk '{ total += $1 } END { print total + 0 }')"
credential_count="$(grep -RhcE 'persist-credentials:[[:space:]]*false' .github/workflows | awk '{ total += $1 } END { print total + 0 }')"
[[ "$credential_count" -ge "$checkout_count" ]] \
    || fail "every checkout must set persist-credentials: false"

build_workflow=".github/workflows/build.yml"
grep -Fq -- '-enableCodeCoverage YES' "$build_workflow" || fail "CI must enable Xcode coverage"
grep -Fq 'check_coverage.sh' "$build_workflow" || fail "CI must enforce the coverage baseline"
grep -Fq 'check_tdd_contract.sh' "$build_workflow" || fail "CI must enforce the TDD change contract"
grep -Fq 'check_repository_contract.sh' "$build_workflow" || fail "CI must enforce repository policy"
grep -Fq 'name: Quality Gate' "$build_workflow" || fail "CI must expose a stable Quality Gate"
grep -Fq 'swiftlint lint --strict' "$build_workflow" || fail "SwiftLint must run in strict mode"
if grep -Fq 'SwiftLint not installed, skipping' "$build_workflow"; then
    fail "SwiftLint may not silently skip"
fi

codeql_workflow=".github/workflows/codeql.yml"
grep -Fq 'build-mode: manual' "$codeql_workflow" || fail "CodeQL must use a manual Swift build"
grep -Fq 'xcodegen generate' "$codeql_workflow" || fail "CodeQL must generate the Xcode project"
grep -Fq 'security-events: write' "$codeql_workflow" || fail "CodeQL needs narrowly scoped security-events access"

release_workflow=".github/workflows/app-store-release.yml"
grep -Fq "github.ref == 'refs/heads/main'" "$release_workflow" || fail "releases must be main-only"
grep -Fq 'environment: app-store-production' "$release_workflow" || fail "releases must use the protected environment"
if grep -Fq 'actions/upload-artifact' "$release_workflow"; then
    fail "signed release artifacts may not be published by Actions"
fi

grep -Fq 'Red test evidence' .github/pull_request_template.md || fail "PR template must request red evidence"
grep -Fq 'Green test evidence' .github/pull_request_template.md || fail "PR template must request green evidence"
grep -Fq 'minimumLineCoverage' .github/coverage-baseline.json || fail "coverage baseline is invalid"

echo "PASS: repository excellence contract"

