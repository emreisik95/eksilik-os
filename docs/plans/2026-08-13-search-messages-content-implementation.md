# Search, Navigation, Messages, and Ekşi Şeyler Implementation Plan

**Goal:** Deliver reliable canonical topic navigation, stable search motion, direct page selection, complete signed-in messages, and isolated Ekşi Şeyler filtering through a test-first hosted build workflow.

**Architecture:** Pure routing, pagination, and filter policies sit in `Core` and are exercised by both XCTest and the platform-independent harness. SwiftUI views consume those policies; services remain responsible for HTTP and parsers remain responsible for server markup.

**Tech Stack:** Swift 5.9, SwiftUI, UIKit text bridge, Kanna, XCTest, Swift Package core harness, XcodeGen, GitHub Actions, Xcode Cloud.

### Task 1: Canonical topic lookup and safe internal links

**Files:**
- Create: `Core/Links/InternalLinkPolicy.swift`
- Create: `EksilikTests/Links/InternalLinkPolicyTests.swift`
- Modify: `Core/Search/SearchPresentation.swift`
- Modify: `EksilikTests/Search/SearchPresentationTests.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `Package.swift`
- Modify: `Views/Entry/EntryTextView.swift`
- Modify: `Views/Entry/EntryRowView.swift`
- Modify: `Core/Parsing/HTMLContentRenderer.swift`

1. Add failing tests for query lookup paths, Turkish/special characters, relative and absolute `bkz` links, malformed links, profiles, entries, and canonical topic paths.
2. Run the core harness and confirm the new expectations fail.
3. Implement the minimal typed policy and map it to app routes.
4. Defer the navigation callback to the main actor and safely encode generated `bkz` links.
5. Re-run targeted and full platform-independent checks.

### Task 2: Stable search transitions

**Files:**
- Create: `Core/Search/SearchMotionPolicy.swift`
- Create: `EksilikTests/Search/SearchMotionPolicyTests.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `Package.swift`
- Modify: `Views/Search/SearchView.swift`

1. Add failing checks proving search state transitions never use scale/geometry motion and respect Reduce Motion.
2. Replace whole-header implicit animation with local color/opacity behavior and a stable-width cancel action.
3. Add an opacity-only state transition selected through the policy.
4. Re-run search and accessibility-oriented checks.

### Task 3: Direct page picker

**Files:**
- Create: `Core/Presentation/PaginationSelectionPolicy.swift`
- Create: `EksilikTests/Entry/PaginationSelectionPolicyTests.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `Package.swift`
- Modify: `Views/Entry/PaginationView.swift`

1. Add failing tests for numeric parsing, whitespace, invalid input, clamping, and quick-page generation near both boundaries.
2. Implement the pure selection policy.
3. Turn the page indicator into an accessible button and add the manual/quick-selection sheet.
4. Re-run pagination tests and the harness.

### Task 4: Message parsing, routing, and sending

**Files:**
- Modify: `Core/Navigation/Route.swift`
- Modify: `Views/Home/TopicListView.swift`
- Modify: `Models/MessageThread.swift`
- Modify: `Core/Parsing/MessageParser.swift`
- Modify: `Core/Parsing/MessageContentParser.swift`
- Create: `EksilikTests/Parsing/MessageParserTests.swift`
- Modify: `ViewModels/MessageListViewModel.swift`
- Modify: `ViewModels/MessageThreadViewModel.swift`
- Create: `ViewModels/MessageComposeViewModel.swift`
- Modify: `Views/Messages/MessageListView.swift`
- Modify: `Views/Messages/MessageThreadView.swift`
- Modify: `Views/Messages/MessageComposeView.swift`
- Modify: `Views/Profile/ProfileView.swift`
- Modify: `Core/Strings.swift`
- Modify: `project.yml`

1. Add failing parser fixtures for current/legacy thread markup, unread state, normalized IDs, empty markup, and conversation messages.
2. Implement tolerant parser helpers and typed message-list navigation.
3. Add the profile envelope/unread indicator and rebuild list/thread states without a nested navigation stack.
4. Add a testable compose view model with CSRF, duplicate-send prevention, retained draft, and surfaced errors.
5. Compare selectors with an authenticated mobile Chrome session and adjust fixtures if the live contract differs.

### Task 5: Ekşi Şeyler request isolation

**Files:**
- Modify: `Models/EntryFilter.swift`
- Modify: `Core/Network/TopicRequest.swift`
- Modify: `ViewModels/EntryListViewModel.swift`
- Modify: `Views/Entry/EntryListView.swift`
- Modify: `EksilikTests/Network/TopicRequestTests.swift`
- Modify: `CoreTestHarness/main.swift`

1. Add failing tests for deriving the active filter from a request and preserving `a=eksiseyler` through canonical replacement and arbitrary page jumps.
2. Implement filter derivation and request invariants.
3. Add an Ekşi Şeyler-specific empty/unavailable state and verify normal entries cannot replace filtered results.
4. Re-run request, parser, and entry-list policy checks.

### Task 6: Hosted verification and Xcode Cloud

**Files:**
- Modify only configuration required by a proven hosted failure.

1. Run the complete core harness locally without Xcode.
2. Review the diff for secrets, signing assets, and unrelated changes.
3. Commit, push, and open a focused PR so repository TDD, coverage, lint, analysis, and unsigned-device checks run.
4. Fix hosted failures test-first and wait for all required checks.
5. Discover and trigger the existing Xcode Cloud workflow for the branch/build, then report its build result and artifact availability without submitting it to App Review.
