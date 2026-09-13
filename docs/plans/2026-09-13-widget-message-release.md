# Widget and Messaging Release Fixes

## Goal

Ship a focused follow-up for the current SwiftUI app that makes the small
WidgetKit feed readable, restores the server's separate new-message endpoint,
and exposes unread messages on the bottom profile tab.

## Scope

1. Add a tested widget layout policy. The small family renders one feed item,
   with multiline wrapping and a conservative scale-down so a long title stays
   readable. Medium and large families keep their existing multi-item layouts.
2. Keep new-message and reply requests distinct. New conversations use
   `/mesaj/sendajax`; replies use `/mesaj/yolla` with `ThreadId` and `IsReply`.
   Prefer the message form's CSRF token, refuse to send without a usable token,
   and preserve normalized form encoding, draft retention, and visible send
   errors.
3. Add a bottom-tab unread badge for the profile tab, driven by the existing
   authenticated-page unread state. Refresh that state when the app returns to
   the foreground, and keep the existing profile-toolbar envelope indicator
   and accessibility value.
4. Add focused XCTest/harness coverage before implementation for widget family
   limits, message endpoint selection, and badge visibility.

## Verification and release boundary

- Run `swift run EksilikCoreHarness` and the repository's static/readiness
  checks.
- Regenerate the Xcode project with XcodeGen and run the available Xcode tests
  if a full Xcode installation is present.
- Inspect the final diff for unrelated changes and verify the release version
  and App Store metadata from the authoritative branch.
- Archive/upload/submit only when the required Xcode and App Store Connect
  credentials are available. A source-level pass is not evidence that a binary
  was uploaded or released.
