#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
checker="$repo_root/.github/scripts/check_tdd_contract.sh"
[[ -f "$checker" ]] || { echo "Missing policy implementation: $checker" >&2; exit 127; }
fixture_repo="$(mktemp -d "${TMPDIR:-/tmp}/eksilik-tdd-test.XXXXXX")"
trap 'rm -rf "$fixture_repo"' EXIT

git -C "$fixture_repo" init -q
git -C "$fixture_repo" config user.name "Eksilik CI"
git -C "$fixture_repo" config user.email "ci@example.invalid"
mkdir -p "$fixture_repo/Core" "$fixture_repo/EksilikTests"
printf '%s\n' 'struct TopicPolicy {}' > "$fixture_repo/Core/TopicPolicy.swift"
printf '%s\n' 'final class TopicPolicyTests {}' > "$fixture_repo/EksilikTests/TopicPolicyTests.swift"
git -C "$fixture_repo" add .
git -C "$fixture_repo" commit -qm "baseline"
base_sha="$(git -C "$fixture_repo" rev-parse HEAD)"

printf '%s\n' 'struct TopicPolicy { let enabled = true }' > "$fixture_repo/Core/TopicPolicy.swift"
git -C "$fixture_repo" add Core/TopicPolicy.swift
git -C "$fixture_repo" commit -qm "change production only"
production_only_sha="$(git -C "$fixture_repo" rev-parse HEAD)"

if bash "$checker" "$base_sha" "$production_only_sha" "$fixture_repo" > "$fixture_repo/production-only.out" 2>&1; then
    echo "Expected a production Swift change without tests to fail" >&2
    exit 1
fi
grep -Fq 'Production Swift changed without an EksilikTests change' "$fixture_repo/production-only.out"

printf '%s\n' 'final class TopicPolicyTests { let coversEnabled = true }' > "$fixture_repo/EksilikTests/TopicPolicyTests.swift"
git -C "$fixture_repo" add EksilikTests/TopicPolicyTests.swift
git -C "$fixture_repo" commit -qm "add regression test"
tested_sha="$(git -C "$fixture_repo" rev-parse HEAD)"

bash "$checker" "$base_sha" "$tested_sha" "$fixture_repo" > "$fixture_repo/tested.out"
grep -Fq 'TDD contract passed: production and test changes move together' "$fixture_repo/tested.out"

bash "$checker" "$production_only_sha" "$tested_sha" "$fixture_repo" > "$fixture_repo/tests-only.out"
grep -Fq 'TDD contract passed: no production Swift changes' "$fixture_repo/tests-only.out"

printf '%s\n' 'struct TopicPolicy { let enabled = false }' > "$fixture_repo/Core/TopicPolicy.swift"
rm "$fixture_repo/EksilikTests/TopicPolicyTests.swift"
git -C "$fixture_repo" add -A
git -C "$fixture_repo" commit -qm "change production and delete tests"
deleted_test_sha="$(git -C "$fixture_repo" rev-parse HEAD)"

if bash "$checker" "$tested_sha" "$deleted_test_sha" "$fixture_repo" > "$fixture_repo/deleted-test.out" 2>&1; then
    echo "Expected deleting a test alongside a production change to fail" >&2
    exit 1
fi
grep -Fq 'Production Swift changed without an EksilikTests change' "$fixture_repo/deleted-test.out"

echo "PASS: TDD change contract"
