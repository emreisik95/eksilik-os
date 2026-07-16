# Offline Reading and Stability Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix filter-aware pagination, unstable skeletons, and broken image viewing; add resumable background offline topic downloads; and repair adjacent reliability defects found during a focused audit.

**Architecture:** A pure-Foundation `TopicRequest` owns topic paths and query state so pagination changes only the page item. Images use a shared actor-backed cache and a SwiftUI lightbox. Offline content uses Codable manifests/pages in Application Support, while one fixed-identifier background `URLSession` performs page and media downloads and reconnects after relaunch.

**Tech Stack:** Swift 5.9, SwiftUI, UIKit interoperability, Foundation `URLSession`, Kanna, XCTest, XcodeGen.

### Task 1: Create a portable core test harness

**Files:**
- Modify: `Package.swift`
- Modify: `Models/Entry.swift`
- Modify: `Models/UserProfile.swift`
- Modify: `EksilikTests/Parsing/AuthParserTests.swift`
- Modify: `EksilikTests/Parsing/EntryPageParserTests.swift`
- Modify: `EksilikTests/Parsing/PaginationParserTests.swift`
- Modify: `EksilikTests/Parsing/TopicListParserTests.swift`

**Steps:**
1. Change model imports from UIKit to Foundation where only `NSAttributedString` is required.
2. Define an `EksilikCore` Swift Package target containing only Foundation/Kanna models, request builders, parsers, and storage code.
3. Add conditional test imports so Xcode uses `EksilikApp` and `swift test` uses `EksilikCore`.
4. Run `swift test` and confirm all existing parsing tests pass on macOS.
5. Commit with `Enable portable core tests`.

### Task 2: Preserve filters through pagination

**Files:**
- Create: `Models/EntryFilter.swift`
- Create: `Core/Network/TopicRequest.swift`
- Create: `EksilikTests/Network/TopicRequestTests.swift`
- Modify: `ViewModels/EntryListViewModel.swift`
- Modify: `Services/EntryService.swift`
- Modify: `Core/Network/EksiEndpoint.swift`

**Steps:**
1. Write failing tests proving that replacing `p` retains `day`, `a`, `period`, `author`, and `keywords`; removes duplicate page items; and accepts absolute and relative links.
2. Run `swift test --filter TopicRequestTests` and confirm expected failures because `TopicRequest` does not exist.
3. Implement `TopicRequest` with a Codable query-item representation and URLComponents-backed rendering.
4. Move `EntryFilter` to a Foundation-only model and express filters as query items.
5. Run the focused tests and confirm they pass.
6. Refactor `EntryService` and `EntryListViewModel` to keep `sourceRequest` and `currentRequest`; make `goToPage` replace only the page item.
7. Add endpoint tests for paginated agenda paths and run the full core suite.
8. Commit with `Preserve topic filters during pagination`.

### Task 3: Stabilize skeletons and list pagination

**Files:**
- Create: `Core/Loading/SkeletonLayout.swift`
- Create: `Views/Shared/SkeletonViews.swift`
- Create: `EksilikTests/Loading/SkeletonLayoutTests.swift`
- Modify: `Views/Home/TopicListView.swift`
- Modify: `Views/Entry/EntryListView.swift`
- Modify: `Views/Profile/ProfileView.swift`
- Modify: `Views/Search/SearchView.swift`
- Modify: `ViewModels/TopicListViewModel.swift`
- Modify: `Services/TopicService.swift`

**Steps:**
1. Write failing tests for deterministic skeleton width fractions and deduplicated page append behavior.
2. Implement fixed skeleton metrics and shared shimmer views whose animation never changes layout.
3. Replace random topic widths and add a profile skeleton matching the final header/list geometry.
4. Add `isLoadingMore` and `hasMore` guards to topic pagination; fetch the requested agenda page instead of repeating page 1; deduplicate topic IDs.
5. Wire the environment `BlockedTopicStore` into the view model rather than the temporary store created in `TopicListView.init`.
6. Run core tests and Swift parse checks.
7. Commit with `Stabilize skeletons and topic pagination`.

### Task 4: Build the image cache and full-screen gallery

**Files:**
- Create: `Core/Images/ImageURLNormalizer.swift`
- Create: `Core/Images/ImagePipeline.swift`
- Create: `Views/Shared/CachedRemoteImage.swift`
- Create: `Views/Shared/ImageLightboxView.swift`
- Create: `EksilikTests/Images/ImageURLNormalizerTests.swift`
- Modify: `Core/Parsing/UserProfileParser.swift`
- Modify: `Views/Entry/EntryTextView.swift`
- Modify: `Views/Entry/EntryRowView.swift`
- Modify: `Views/Profile/ProfileView.swift`
- Modify: `ViewModels/EntryListViewModel.swift`
- Modify: `ViewModels/UserProfileViewModel.swift`

**Steps:**
1. Write failing tests for protocol-relative URLs, HTML entities, file extensions with query strings, invalid URLs, and ordered deduplication.
2. Implement URL normalization and update parsers to preserve source order.
3. Run focused tests and confirm they pass.
4. Implement an actor-backed memory/URL cache that reuses in-flight requests and shared cookies, plus prefetch support.
5. Implement `CachedRemoteImage`, loading/error/retry states, zoomable paging lightbox, and a visible close control.
6. Route image links from `EntryTextView` to the lightbox and replace the currently undefined `CookieImage`/`ImageLightboxView` references.
7. Use the same pipeline for entry/profile images and prefetch URLs after page loads.
8. Run core tests, parse every Swift file, and generate the Xcode project.
9. Commit with `Add cached images and full screen gallery`.

### Task 5: Add offline models and atomic storage

**Files:**
- Create: `Models/OfflineTopic.swift`
- Create: `Core/Storage/OfflineTopicStore.swift`
- Create: `EksilikTests/Storage/OfflineTopicStoreTests.swift`
- Create: `EksilikTests/Storage/OfflineDownloadPlannerTests.swift`

**Steps:**
1. Write failing tests for 5/10/all page limits, manifest progress, atomic round-trips, ordered entry deduplication, media filename stability, deletion, and recovery from a corrupt manifest.
2. Run the focused tests and confirm expected missing-type failures.
3. Implement Codable manifests, page snapshots, entry conversion, task descriptors, and the page planner.
4. Implement an actor store with an injectable root directory, atomic writes, topic isolation, media lookup, and corruption quarantine.
5. Run focused and full core tests.
6. Commit with `Add offline topic storage`.

### Task 6: Implement background page and media transfers

**Files:**
- Create: `App/AppDelegate.swift`
- Create: `Services/OfflineDownloadManager.swift`
- Modify: `App/EksilikApp.swift`
- Modify: `App/RootView.swift`

**Steps:**
1. Recreate one fixed-identifier background session at launch with a delegate, launch events, shared cookies, two host connections, and discretionary scheduling.
2. Encode topic/page/media metadata in each task description so callbacks recover after process termination.
3. Schedule page 1 first, parse total pages, queue the bounded remaining set together, persist each completed page immediately, and queue discovered images.
4. Implement progress, bounded retry, cancellation, relaunch reconciliation, permanent file movement, and background completion-handler delivery on the main thread.
5. Allow `RootView` to reach the application and offline library when bootstrap networking fails.
6. Run core tests, Swift parse checks, and XcodeGen generation.
7. Commit with `Download offline topics in the background`.

### Task 7: Add offline download and reading UI

**Files:**
- Create: `Views/Offline/DownloadOptionsView.swift`
- Create: `Views/Offline/OfflineLibraryView.swift`
- Create: `Views/Offline/OfflineTopicView.swift`
- Create: `ViewModels/OfflineLibraryViewModel.swift`
- Modify: `App/ContentView.swift`
- Modify: `App/RootView.swift`
- Modify: `Views/Entry/EntryListView.swift`
- Modify: `Core/Strings.swift`

**Steps:**
1. Add a topic toolbar download action and an options sheet for normal/şükela plus 5/10/all pages.
2. Add the fifth “çevrimdışı” tab with progress, retry, cancel, delete, timestamp, entry count, and storage size.
3. Render saved pages with existing typography and cached local media while hiding network-only actions.
4. Add accessibility labels and empty/error states.
5. Run core tests, parse checks, and XcodeGen generation.
6. Commit with `Add offline reading interface`.

### Task 8: Finish the bug audit and verification

**Files:**
- Modify as evidence requires: `ViewModels/UserProfileViewModel.swift`, `Views/Profile/ProfileView.swift`, `ViewModels/TopicListViewModel.swift`, and affected tests
- Update: `README.md`
- Update: `docs/plans/2026-07-16-offline-reading-and-stability-design.md`

**Steps:**
1. Add failing tests for ordered profile image extraction, stale profile tab responses, duplicate load-more calls, and end-of-list behavior where testable.
2. Fix profile load-more visibility, stale response replacement, repeated `.task` loads, and duplicate entries.
3. Search for force unwraps, random layout, undefined referenced types, raw query concatenation, and unbounded page requests; fix confirmed user-reachable defects only.
4. Run `swift test`, `swiftc -frontend -parse` over all Swift files, `xcodegen generate`, `git diff --check`, and `git status --short`.
5. Document that a full `xcodebuild`/simulator run remains pending because this machine has no Xcode installation.
6. Request code review, apply verified findings, and commit with `Harden offline reading and loading flows`.
