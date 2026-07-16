# Offline Read State Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let users persistently mark downloaded entries read or unread with either swipe direction and optionally hide read entries after a one-time onboarding.

**Architecture:** Store read IDs and the per-topic hide preference in a separate atomic `read-state.json`, preserving compatibility with existing manifests and background page downloads. The reader view model owns rendered entries plus read state, exposes filtered entries, and persists mutations through `OfflineTopicStore`; SwiftUI supplies bidirectional swipe actions, the toolbar filter, and onboarding.

**Tech Stack:** Swift 5.9, SwiftUI, Foundation actors and Codable, XCTest, Swift Package core harness.

### Task 1: Persistent read-state model and store

**Files:**
- Modify: `Models/OfflineTopic.swift`
- Modify: `Core/Storage/OfflineTopicStore.swift`
- Test: `EksilikTests/Storage/OfflineTopicStoreTests.swift`
- Test: `CoreTestHarness/main.swift`

**Step 1: Write the failing tests**

Add tests that mark entry `1` read, reload the state, mark it unread, and persist `hidesReadEntries`. Add a core check proving that hiding returns only unread entries.

**Step 2: Run the test to verify it fails**

Run: `swift run EksilikCoreHarness`

Expected: FAIL because `OfflineReadState` and store read-state methods do not exist.

**Step 3: Write the minimal implementation**

Add a Codable `OfflineReadState` with a `Set<String>` of read IDs, a hide flag, `isRead`, `settingRead`, and entry filtering. Add `loadReadState`, `setEntryRead`, and `setHidesReadEntries` actor methods backed by atomic `read-state.json` writes. Treat a missing file as the empty state.

**Step 4: Run tests to verify they pass**

Run: `swift run EksilikCoreHarness`

Expected: all core checks pass.

### Task 2: Reader state and filtering

**Files:**
- Modify: `ViewModels/OfflineLibraryViewModel.swift`
- Modify: `Views/Offline/OfflineTopicView.swift`

**Step 1: Implement view-model mutations**

Load stored entries and read state together. Expose `visibleEntries`, `hasDownloadedEntries`, `isRead`, `toggleRead`, and `toggleHidingReadEntries`, updating published state only after persistence succeeds.

**Step 2: Add reader interactions**

Render `visibleEntries`; add full-swipe actions on both leading and trailing edges. Show a read badge and reduced opacity for read rows, add the eye toolbar toggle, and show a filtered empty state with a restore button.

**Step 3: Add one-time onboarding**

Use `@AppStorage("hasSeenOfflineReadSwipeOnboarding")` and a medium-height sheet explaining bidirectional swipes and the eye button. Mark onboarding seen on dismissal.

### Task 3: Verification and device delivery

**Files:**
- Modify: none

**Step 1: Run local verification**

Run the core harness, parse changed Swift files, and run `git diff --check`.

**Step 2: Commit and push**

Commit the implementation and push `codex/offline-reading-bugfixes`.

**Step 3: Verify CI and install**

Require the GitHub Build & Test workflow and device-artifact workflow to succeed. Download the artifact, sign the app and widget with the existing development profiles, install it on iPhone 17, and launch it.
