# Repository Excellence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add enforceable TDD, coverage, security, CI, and community-health standards to the public iOS repository.

**Architecture:** Shell contract tests define the repository policy and are written before the scripts/workflows that satisfy it. GitHub Actions runs deterministic lint, simulator coverage, device build, dependency review, and manual-build CodeQL jobs; one stable aggregator becomes the protected-branch gate.

**Tech Stack:** GitHub Actions, Bash, jq, Xcode/xcodebuild/xccov, SwiftLint, XcodeGen, CodeQL, Dependabot.

### Task 1: Repository policy tests

**Files:**
- Create: `.github/scripts/test_coverage_gate.sh`
- Create: `.github/scripts/test_tdd_contract.sh`
- Create: `.github/scripts/test_repository_contract.sh`

1. Write fixture-driven tests for coverage pass/fail, production-code-without-tests failure, and immutable workflow/community policy.
2. Run each test and verify RED because the policy scripts and required files do not exist.
3. Commit the red tests.

### Task 2: Coverage and TDD policy scripts

**Files:**
- Create: `.github/scripts/check_coverage.sh`
- Create: `.github/scripts/check_tdd_contract.sh`
- Create: `.github/scripts/check_repository_contract.sh`
- Create: `.github/coverage-baseline.json`

1. Implement the smallest Bash/jq scripts that satisfy the fixtures.
2. Run all policy tests and verify GREEN.
3. Run ShellCheck and fix only actionable findings.
4. Commit the policy implementation with coverage enforcement initially in report-only mode.

### Task 3: Harden and consolidate CI

**Files:**
- Modify: `.github/workflows/build.yml`
- Modify: `.github/workflows/device-build.yml`
- Modify: `.github/workflows/app-store-release.yml`
- Modify: `.github/dependabot.yml`
- Create: `.github/workflows/codeql.yml`

1. Update actions to verified full-length SHAs and disable persisted checkout credentials.
2. Make SwiftLint installation/execution mandatory.
3. Run simulator tests once with code coverage and diagnostic result artifacts.
4. Add TDD contract, dependency review, actionlint/ShellCheck, and a stable `Quality Gate` aggregator.
5. Replace default CodeQL autobuild with a manual XcodeGen iOS build.
6. Run repository contract tests and YAML parsing locally.
7. Commit and push the reporting-mode CI.

### Task 4: Measure and enforce baseline coverage

**Files:**
- Modify: `.github/coverage-baseline.json`
- Modify: `.github/workflows/build.yml`

1. Open a draft pull request and wait for the first coverage report.
2. Record the measured app line coverage without rounding it upward.
3. Turn report-only coverage into a required ratchet.
4. Verify the gate fails against a deliberately higher fixture baseline and passes at the measured baseline.
5. Commit and push the enforced baseline.

### Task 5: Community health and contributor guidance

**Files:**
- Create: `.github/CODEOWNERS`
- Create: `.github/pull_request_template.md`
- Create: `.github/ISSUE_TEMPLATE/bug_report.yml`
- Create: `.github/ISSUE_TEMPLATE/feature_request.yml`
- Create: `.github/ISSUE_TEMPLATE/config.yml`
- Create: `SECURITY.md`
- Create: `CODE_OF_CONDUCT.md`
- Create: `SUPPORT.md`
- Modify: `CONTRIBUTING.md`
- Modify: `README.md`

1. Add forms and policies with no private contact data.
2. Document red/green evidence, coverage, verification commands, security reporting, and the real root-level setup.
3. Run repository contract tests and GitHub community-profile validation.
4. Commit the documentation package.

### Task 6: Repository settings and final verification

**Files:** None (GitHub settings)

1. Enable auto-merge and automatic branch deletion; disable merge commits while preserving squash and rebase.
2. Keep Actions default permissions read-only and production deployments restricted to `main`.
3. Require the stable Quality Gate and CodeQL checks after they have reported successfully.
4. Verify PR CI, main protection, secret/dependency/code-scanning alerts, public artifacts, and community health.
5. Request code review, address findings, mark the PR ready, and merge only after every required check is green.

