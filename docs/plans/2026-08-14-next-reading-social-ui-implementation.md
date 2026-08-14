# Next Reading and Social UI Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver the next tested ek$ilik update covering entry rendering, navigation, messages, profile/social fixes, offline Şeyler, adaptive spacing, and app icons.

**Architecture:** Keep network parsing and state in services/view models, put deterministic decisions in pure core policies, and let SwiftUI views consume those policies. Reuse production views instead of parallel previews. Store native offline article snapshots atomically in Application Support.

**Tech Stack:** Swift 5.9, SwiftUI, UIKit bridges, Kanna, URLSession, XCTest, SwiftPM core harness, XcodeGen/xcodebuild, WidgetKit, App Store Connect CLI.

---

### Task 1: Production entry preview and adaptive metrics

**Files:**
- Modify: `Core/Presentation/EntryLayoutStyle.swift`
- Modify: `Views/Entry/EntryRowView.swift`
- Modify: `Views/Settings/EntryLayoutPickerView.swift`
- Test: `EksilikTests/Entry/EntryLayoutRenderingPolicyTests.swift`
- Test: `CoreTestHarness/main.swift`

1. Add failing tests for style override and clamped font-size geometry.
2. Run focused tests/harness and observe the missing-policy failure.
3. Implement `EntryRowRenderingPolicy` and `EntryLayoutMetrics`.
4. Add a defaulted style override to `EntryRowView` and apply metrics to row geometry.
5. Replace the handcrafted preview with a noninteractive production `EntryRowView` sample.
6. Run tests and refactor duplicated constants.

### Task 2: Page-top identity and Home reselection

**Files:**
- Modify: `Core/Presentation/EntryListChromePolicy.swift`
- Modify: `Views/Entry/EntryListView.swift`
- Modify: `Core/Navigation/DeepLinkRouter.swift`
- Modify: `App/ContentView.swift`
- Modify: `Views/Home/HomeTabView.swift`
- Test: `EksilikTests/Entry/EntryListChromePolicyTests.swift`
- Test: `EksilikTests/Settings/MainTabTests.swift`
- Test: `CoreTestHarness/main.swift`

1. Add failing tests for page-sensitive list identity and same-tab Home reselection.
2. Implement the identities/token API.
3. Wire the custom TabView binding and Home reset behavior.
4. Run focused and harness tests.

### Task 3: Safe conversational messages

**Files:**
- Add: `Core/Messages/MessageBubblePresentation.swift`
- Modify: `ViewModels/MessageComposeViewModel.swift`
- Modify: `ViewModels/MessageThreadViewModel.swift`
- Modify: `Views/Messages/MessageThreadView.swift`
- Test: `EksilikTests/Messages/MessageComposeViewModelTests.swift`
- Test: `EksilikTests/Messages/MessageBubblePresentationTests.swift`
- Test: `CoreTestHarness/main.swift`

1. Add failing bubble-direction and send-cycle tests.
2. Implement presentation policy and draft reset/send generation.
3. Replace List/HTML rendering with a ScrollView conversation and inline composer.
4. Reload and scroll after send; keep failed drafts intact.
5. Run parser, compose, and bubble tests.

### Task 4: Profile connections, avatar, refresh, and title cleanup

**Files:**
- Modify: `Core/Network/EksiEndpoint.swift`
- Modify: `Core/Auth/SessionManager.swift`
- Modify: `Services/UserService.swift`
- Modify: `ViewModels/ProfileConnectionsViewModel.swift`
- Modify: `ViewModels/UserProfileViewModel.swift`
- Modify: `Views/Profile/ProfileConnectionsView.swift`
- Modify: `Views/Profile/ProfileView.swift`
- Modify: `Views/Settings/SettingsView.swift`
- Test: `EksilikTests/Network/MessageRequestTests.swift`
- Test: `EksilikTests/Profile/ProfileConnectionsTests.swift`
- Test: `CoreTestHarness/main.swift`

1. Add failing tests proving connection requests omit AJAX and refresh can replace content.
2. Fix request policy and add force-reload APIs.
3. Persist/update avatar identity and load it in Settings.
4. Remove duplicate username and add pull-to-refresh to both profile lists.
5. Run focused tests.

### Task 5: Offline Ekşi Şeyler

**Files:**
- Add: `Models/OfflineSeylerArticle.swift`
- Add: `Core/Storage/OfflineSeylerStore.swift`
- Modify: `Models/SeylerArticle.swift`
- Modify: `ViewModels/SeylerArticleViewModel.swift`
- Modify: `Views/Seyler/SeylerReaderView.swift`
- Modify: `ViewModels/OfflineLibraryViewModel.swift`
- Modify: `Views/Offline/OfflineLibraryView.swift`
- Test: `EksilikTests/Storage/OfflineSeylerStoreTests.swift`
- Test: `CoreTestHarness/main.swift`

1. Add failing round-trip, deduplication, and delete tests using a temporary store root.
2. Implement Codable article snapshots and atomic storage/media lookup.
3. Add save/delete state and offline-first loading to the view model.
4. Add save toolbar state and an offline article section in the library.
5. Run focused tests and an offline-network smoke test.

### Task 6: Adaptive Settings geometry

**Files:**
- Modify: `Core/Presentation/SettingsPresentationPolicy.swift`
- Modify: `Views/Settings/SettingsTypography.swift`
- Modify: `Views/Settings/SettingsView.swift`
- Test: `EksilikTests/Settings/SettingsPresentationPolicyTests.swift`
- Test: `CoreTestHarness/main.swift`

1. Add failing tests for monotonic/clamped spacing metrics.
2. Implement the metrics and replace fixed row/icon geometry.
3. Verify 10-, 15-, and 24-point settings visually and with tests.

### Task 7: Oldschool primary icon and generated alternatives

**Files:**
- Modify: `Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Add: `Resources/AlternateIcons/AlternateAurora*`
- Add: `Resources/AlternateIcons/AlternateGlow*`
- Add: `Resources/AlternateIcons/AlternateDepth*`
- Add: `Resources/AlternateIcons/AlternateForest*`
- Modify: `EksilikApp-Info.plist`
- Modify: `Views/Settings/AppIconPickerView.swift`
- Modify: `Views/Settings/SettingsView.swift`

1. Restore the initial-release flat droplet as the primary icon.
2. Resize the four generated source images to every required iPhone/iPad alternate-icon slot.
3. Register icons for iPhone/iPad and expose English display names.
4. Validate asset dimensions and inspect every source visually.

### Task 8: Release verification and distribution

**Files:**
- Modify: `project.yml`
- Regenerate: `EksilikApp.xcodeproj`

1. Bump to a marketing version greater than the approved 2.0.2 and a globally higher build number.
2. Run all XCTest/core harness/contract/coverage/lint/security/App Store preflight checks.
3. Build main app and widget on simulator; archive and export the signed IPA.
4. Upload to App Store Connect, wait for processing, distribute to TestFlight, and attach the processed build to the new App Store version.
5. Confirm submission state, then commit, push, open a PR, and merge only after required checks are green.
