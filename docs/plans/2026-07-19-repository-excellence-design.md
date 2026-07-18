# Repository Excellence Design

## Goal

Turn `emreisik95/eksilik-os` into a reproducible, secure, contributor-friendly repository whose protected branch accepts only tested changes that preserve code coverage and include test evidence for production Swift changes.

## Quality architecture

Pull requests use one stable `Quality Gate` check. It aggregates repository-contract tests, enforced SwiftLint, iOS simulator tests with code coverage, the unsigned device build, and dependency review. The iOS test job runs once with coverage enabled and publishes a compact summary; its `.xcresult` and coverage JSON are retained only when useful for diagnosis. A checked-in coverage baseline acts as a ratchet: coverage may rise, but may not fall below the measured main-branch value.

TDD order cannot be proven from a final Git diff. The repository therefore enforces the strongest honest approximation: any production Swift change must include an `EksilikTests` change, coverage may not regress, and the pull request template requires the author to record the failing test and the green command. These controls make untested feature code unmergeable without pretending a checkbox can cryptographically prove development order.

## Supply-chain and workflow security

Every third-party action is pinned to a full commit SHA and checkout credentials are not persisted. Workflow tokens stay read-only except for CodeQL's narrowly scoped `security-events: write`. The release workflow remains manual, main-only, environment-protected, and never uploads a signed IPA as a public artifact. CI tools are installed deterministically and their presence is mandatory; a missing linter fails instead of silently skipping.

Default CodeQL autobuild is replaced by advanced Swift analysis with the same XcodeGen and explicit iOS build used by the app. Dependency review blocks newly introduced vulnerable packages. Shell contract tests reject mutable action references, broad permissions, `pull_request_target`, fake linting, or removal of the coverage/TDD gates.

## Community and governance

The repository gains issue forms, a pull request template, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `SUPPORT.md`, and `CODEOWNERS`. README and CONTRIBUTING commands match the actual root layout and CI behavior. Repository settings favor squash/rebase, automatically delete merged branches, keep workflow tokens read-only, and retain strict main protection. Git history and authorship are not rewritten; GitHub currently reports only `emreisik95` as a contributor.

## Rollout

The first CI run reports actual app coverage without enforcing a guessed percentage. That measured value is committed as the baseline in a second red/green cycle, after which `Quality Gate` becomes the required branch check. Major runtime dependency upgrades remain separate Dependabot pull requests even when CI is green, so repository maintenance cannot silently alter the App Store build under review.

