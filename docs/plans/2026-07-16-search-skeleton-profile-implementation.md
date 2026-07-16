# Search, Skeleton, and Profile Connections Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver a redesigned search tab, viewport-filling stable skeletons, tappable profile follower/following lists, and deploy the verified build to iPhone 17.

**Architecture:** Keep the current SwiftUI navigation and network services, add small pure policies for screen state and viewport row calculation, and parse profile connection links from server HTML instead of guessing them. Reuse one people-list flow for both followers and following.

**Tech Stack:** Swift 5.9, SwiftUI, async/await, Kanna, XCTest, Swift Package core harness, XcodeGen, GitHub Actions, `devicectl`.

### Task 1: Prove and fix viewport skeleton coverage

**Files:**
- Modify: `Core/Loading/SkeletonLayout.swift`
- Modify: `EksilikTests/Loading/SkeletonLayoutTests.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `Views/Shared/SkeletonViews.swift`

1. Add failing tests showing a tall viewport requires enough entry, topic, profile, and search rows to cover its remaining height.
2. Run `swift run EksilikCoreHarness` and confirm the new row-count check fails because the API does not exist.
3. Add a deterministic row-count calculation with minimum and overscan behavior.
4. Run the harness and confirm the layout checks pass.
5. Wrap skeleton surfaces in `GeometryReader`, derive their row counts, and fill the entire available frame/background.

### Task 2: Redesign search behavior and presentation

**Files:**
- Create: `Core/Search/SearchPresentation.swift`
- Modify: `Package.swift`
- Create: `EksilikTests/Search/SearchPresentationTests.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `ViewModels/SearchViewModel.swift`
- Replace: `Views/Search/SearchView.swift`
- Modify: `Views/Shared/SkeletonViews.swift`

1. Add failing tests for trimmed queries, minimum query length, loading/results/empty/error states, and existing `#entry`/`@author`/topic routing.
2. Run the core harness and verify the new search policy checks fail before implementation.
3. Implement the pure search presentation policy and expose error state from the view model.
4. Run the harness and targeted XCTest-equivalent checks until green.
5. Replace `.searchable` with a 52-point custom search field, larger result cards, channel discovery, full-screen loading, and explicit empty/error states.
6. Parse all touched Swift files and run `git diff --check`.

### Task 3: Add follower and following destinations

**Files:**
- Modify: `Models/UserProfile.swift`
- Create: `Models/ProfileConnection.swift`
- Modify: `Core/Parsing/UserProfileParser.swift`
- Modify: `Services/UserService.swift`
- Create: `ViewModels/ProfileConnectionsViewModel.swift`
- Create: `Views/Profile/ProfileConnectionsView.swift`
- Modify: `Views/Profile/ProfileView.swift`
- Create: `EksilikTests/Profile/ProfileConnectionsTests.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `Package.swift`

1. Add failing parser tests for real follower/following anchor links, ordered unique people, and absent/private lists.
2. Run the harness and confirm the parser expectations fail.
3. Extend the profile model/parser with optional server-provided links and add the connection-list parser.
4. Add the service, view model, and reusable people list.
5. Turn available profile stats into large navigation controls and retain plain text when the site does not provide a destination.
6. Run all core checks and parser tests.

### Task 4: Verify, publish, and deploy

**Files:**
- Modify only if verification exposes a defect.

1. Run `swift run EksilikCoreHarness`, Swift parsing, `git diff --check`, and repository status checks.
2. Commit focused changes and push `codex/offline-reading-bugfixes`.
3. Trigger/inspect the device artifact workflow and confirm the device build succeeds.
4. Download the unsigned artifact, embed the existing main/widget profiles, sign nested dylibs and extensions before the app, and run deep signature verification.
5. Install to paired device `D991671C-B62D-5D76-8FA1-75CB0D3B79AB`, launch while unlocked, and verify the app process stays alive.
