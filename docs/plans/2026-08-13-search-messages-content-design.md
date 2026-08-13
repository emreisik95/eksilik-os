# Search, Navigation, Messages, and Ekşi Şeyler Design

## Goal

Make search and in-entry links resolve existing topics reliably, remove the search screen's top-leading growth animation, let readers jump directly to any topic page, expose the existing message capability as a complete signed-in flow, and ensure the Ekşi Şeyler filter never leaks ordinary topic entries.

The implementation must remain test-first and must be buildable by the repository's hosted checks and Xcode Cloud. No local Xcode installation is part of the workflow.

## Search and internal-link routing

Ekşi Sözlük autocomplete returns display strings rather than canonical topic paths. The mobile website resolves those strings through `/?q=<query>` and redirects to a canonical slug containing the topic ID. The app will use that same lookup route for typed topic searches, autocomplete selections, and `bkz` links instead of inventing a slug from display text.

A pure internal-link policy will normalize relative links, Ekşi Sözlük URLs, and `applewebdata` URLs emitted by `NSAttributedString`. It will reject unsupported or malformed links and return typed destinations for topic lookup, canonical topic, profile, and entry routes. The text-view delegate will hand navigation back asynchronously on the main actor so a `NavigationPath` mutation never occurs inside UIKit's interaction callback.

Search uses a stable layout. Focus changes may alter color and reveal the cancel control, but they do not animate the whole header's geometry. Result state changes use opacity only and disable animation when Reduce Motion is enabled.

## Direct page selection

The compact four pagination buttons stay unchanged. The center page capsule becomes a button that opens a medium-height sheet. The sheet includes a numeric field, a clear current/total-page summary, first and last shortcuts, and a compact grid of nearby pages. A pure selection policy trims input, rejects non-numeric values, clamps valid numbers to the available range, and produces deterministic quick-page choices.

## Messages

Messages remain a signed-in feature and do not add a sixth main tab. The signed-in user's root profile gets a trailing envelope button with an unread indicator derived from `SessionManager`. It pushes a message-list route inside the existing profile `NavigationStack`.

The list shows sender, unread state, message count, preview, and date; supports refresh, pagination, empty state, and retry. Selecting a row opens the conversation, and the conversation exposes reply. Sending uses the current CSRF token, preserves the draft on failure, surfaces the error, prevents duplicate sends, and dismisses only after success. Message links are normalized once so `/mesaj/<id>` is never accidentally requested as `/mesaj//mesaj/<id>`.

## Ekşi Şeyler isolation

The Ekşi Şeyler chip is a server-backed topic filter using `a=eksiseyler`. Its query context must survive canonical topic replacement and every page change. The view model will derive its active filter from the incoming request, keep the filter during navigation, and refuse to reinterpret an Ekşi Şeyler request as the unfiltered topic. Empty or unavailable Ekşi Şeyler results receive a filter-specific empty state rather than ordinary entries.

## Verification

Every pure policy and parser change starts with failing XCTest and core-harness checks. Hosted verification covers the full XCTest suite, coverage/TDD gates, lint, unsigned device build, and static analysis. Chrome is used only for read-only comparison with current mobile-web behavior. After the PR is green, the same branch/build is run through the existing Xcode Cloud workflow; no App Store submission is implied by a successful build.
