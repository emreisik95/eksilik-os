# Contributing to ek$ilik

Thanks for improving ek$ilik. Keep pull requests focused, test-driven, and safe for a public repository.

## Development setup

You need a complete Xcode installation, iOS 16+ simulator support, and XcodeGen 2.46.0 or newer.

```bash
git clone https://github.com/emreisik95/eksilik-os.git
cd eksilik-os
xcodegen generate
open EksilikApp.xcodeproj
```

Create a short-lived branch from current `main`. Do not commit the generated Xcode project, derived data, signing assets, credentials, session cookies, or personal test data.

## Test-driven workflow

Every behavior change follows red, green, refactor:

1. Add the smallest test that describes the missing behavior.
2. Run it and confirm it fails for the intended reason.
3. Implement the smallest production change that makes it pass.
4. Run the focused test, then the full suite.
5. Refactor only while the suite remains green.

Production Swift changes must include an `EksilikTests` change. The CI coverage baseline is a ratchet: coverage may increase, but a pull request cannot reduce it below the recorded baseline. Mechanical, documentation-only, or CI-only changes do not need artificial Swift tests.

## Verification

Fast, platform-independent checks:

```bash
swift run EksilikCoreHarness
bash .github/scripts/test_coverage_gate.sh
bash .github/scripts/test_tdd_contract.sh
bash .github/scripts/test_verified_tool_install.sh
bash .github/scripts/test_repository_contract.sh
```

Full iOS suite:

```bash
xcodegen generate
xcodebuild test \
  -project EksilikApp.xcodeproj \
  -scheme EksilikApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -enableCodeCoverage YES \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO
```

Also run SwiftLint in strict mode and manually verify affected UI flows. Include screenshots or a recording for visual changes, and test signed-in, signed-out, offline, Dynamic Type, and VoiceOver states when relevant.

## Pull requests

Complete the pull request template, including red and green test evidence. Explain risk, App Store impact, dependency changes, migrations, and any manual verification. All required checks must pass; do not bypass the quality gate or weaken the coverage baseline to make a change green.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Security reports must follow [SECURITY.md](SECURITY.md).
