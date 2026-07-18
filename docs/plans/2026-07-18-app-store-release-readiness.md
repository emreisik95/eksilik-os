# App Store Release Readiness Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Produce and submit a validated ek$ilik 2.0.0 App Store build.

**Architecture:** Keep App Store requirements declarative in plist/privacy files, expose legal and moderation entry points through existing Settings and entry action surfaces, and enforce the release contract with a repository validation script. Use GitHub-hosted public policy/support documents and App Store Connect for distribution metadata.

**Tech Stack:** SwiftUI, XcodeGen, plist/privacy manifest, Swift Package core harness, GitHub Actions, App Store Connect.

### Task 1: Add failing readiness checks

**Files:**
- Create: `.github/scripts/validate-app-store-readiness.sh`
- Modify: `CoreTestHarness/main.swift`

1. Check dynamic version/build plist values, encryption exemption, privacy manifest, public documents, moderation UI, and alternate icon dimensions.
2. Run the checks and confirm they fail on the missing release requirements.

### Task 2: Implement minimum compliance changes

**Files:**
- Modify: `EksilikApp-Info.plist`
- Modify: `EksilikWidget-Info.plist`
- Create: `Resources/PrivacyInfo.xcprivacy`
- Create: `PRIVACY.md`
- Create: `SUPPORT.md`
- Modify: `Core/Presentation/SettingsPresentationPolicy.swift`
- Modify: `Views/Settings/SettingsView.swift`
- Modify: `Core/Strings.swift`
- Modify: `Services/EntryService.swift`
- Modify: `Views/Entry/EntryRowView.swift`
- Modify: alternate icon PNG files

1. Implement only the requirements covered by the failing checks.
2. Run the readiness check and core harness until both pass.

### Task 3: Build and integrate

**Files:**
- Modify: `.github/workflows/build.yml`

1. Add the readiness check to CI.
2. Generate the Xcode project and run the simulator build/tests in GitHub Actions.
3. Review, commit, push, and merge the release branch.

### Task 4: Configure and submit App Store version

1. Resolve or create the App Store Connect app record for `com.eksilik.app`.
2. Configure Turkish metadata, privacy, support, category, age rating, content rights, availability, and review notes.
3. Create App Store distribution signing assets, archive build 2.0.0 with a unique build number, upload, and wait for processing.
4. Attach screenshots and the processed build, validate submission health, and submit for review.
