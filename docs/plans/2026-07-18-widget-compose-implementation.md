# Widget and Entry Composer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add secure feed widgets and replace the entry composer with a cursor-aware, draft-safe full-screen writing experience, then prepare the result for TestFlight only.

**Architecture:** Shared Codable widget models and an App Group snapshot store bridge the authenticated app and widget without sharing cookies. Pure entry formatting/draft helpers sit below a SwiftUI composer and a small UITextView bridge for selection-aware insertion.

**Tech Stack:** Swift 5.9, SwiftUI, WidgetKit, AppIntents, UIKit text view bridge, XCTest, XcodeGen.

### Task 1: Shared widget contracts and snapshot storage

**Files:**
- Create: `Core/Widget/WidgetFeed.swift`
- Create: `Core/Widget/WidgetSnapshotStore.swift`
- Create: `EksilikTests/Widget/WidgetSnapshotStoreTests.swift`
- Modify: `project.yml`

1. Write failing tests proving stable link IDs, source round-tripping, last-good snapshot persistence and source isolation.
2. Run the targeted XCTest through CI-compatible project generation and confirm the missing types fail compilation.
3. Implement minimal Codable models and dependency-injected UserDefaults storage.
4. Run the targeted tests and full test suite.

### Task 2: Feed parsing and app-to-widget synchronization

**Files:**
- Create: `Core/Widget/WidgetFeedParser.swift`
- Create: `EksilikTests/Widget/WidgetFeedParserTests.swift`
- Modify: `ViewModels/TopicListViewModel.swift`

1. Add failing fixtures/tests for gündem rows, debe entry links and empty HTML.
2. Implement parser output as shared `WidgetFeedItem` values.
3. Save successful popular/today/following/debe loads to the shared store and request timeline reloads.
4. Verify parser and existing topic-list tests.

### Task 3: Configurable feed widget and quick-access widget

**Files:**
- Modify: `EksilikWidget/EksilikWidget.swift`
- Modify: `EksilikWidget/PopularTopicsProvider.swift`
- Modify: `EksilikWidget/WidgetTopicView.swift`
- Modify: `EksilikWidget/EksilikWidgetBundle.swift`
- Create: `EksilikWidget/QuickAccessWidget.swift`
- Modify: `Core/Navigation/DeepLinkRouter.swift`
- Modify: `Core/Navigation/Route.swift`
- Modify: `Views/Home/TopicListView.swift`
- Create: `EksilikTests/Widget/WidgetDeepLinkTests.swift`

1. Write failing deep-link mapping tests for gündem, bugün, takip and debe.
2. Add `.following`, cached fallback and native source labels to the timeline provider.
3. Redesign feed rows with source icon, freshness and accessible tappable links.
4. Add the shortcut grid widget and native feed routing.
5. Verify generated widget extension sources and deep-link tests.

### Task 4: Cursor-aware formatting and drafts

**Files:**
- Create: `Core/Compose/EntryFormatting.swift`
- Create: `Core/Compose/EntryDraftStore.swift`
- Create: `EksilikTests/Entry/EntryFormattingTests.swift`
- Create: `EksilikTests/Entry/EntryDraftStoreTests.swift`
- Modify: `ViewModels/EntryComposeViewModel.swift`

1. Write failing tests for replacing a selection, inserting at a cursor, bkz/hede/spoiler/link output and bounds clamping.
2. Write failing draft save/restore/clear and per-topic isolation tests.
3. Implement minimal pure helpers, then integrate draft restoration, debounced saves, submit guarding and draft clearing into the view model.
4. Run targeted and existing entry tests.

### Task 5: Entry composer redesign

**Files:**
- Modify: `Views/Entry/EntryComposeView.swift`
- Create: `Views/Entry/EntryTextEditor.swift`
- Create: `Views/Entry/EntryFormatSheet.swift`

1. Build a UITextView representable that reports and restores `NSRange` selection.
2. Replace the old bordered full-screen editor with focused navigation, placeholder, save/count status and keyboard-safe formatting toolbar.
3. Add format input sheets, icon-only back navigation, disabled/loading send state, error alert and hidden tab bar.
4. Verify Dynamic Type labels, VoiceOver descriptions, dark/light themes and iPad layout.

### Task 6: App Group configuration and release verification

**Files:**
- Create: `EksilikApp.entitlements`
- Create: `EksilikWidget.entitlements`
- Modify: `project.yml`
- Modify: `.github/scripts/validate-app-store-readiness.sh`

1. Add a failing readiness assertion for the shared App Group and both entitlement files.
2. Configure `group.emre.isik.Eksilik` for app and widget targets.
3. Regenerate the Xcode project and run readiness, XCTest and unsigned device build.
4. Open a PR, wait for all checks and keep the build out of App Store submission.
5. After the current version is approved, regenerate profiles with the App Group capability, increment build/version and publish only to TestFlight.
