# Next Reading and Social UI Design

**Date:** 2026-08-14

## Goal

Ship the next ek$ilik update with trustworthy entry previews, predictable navigation, crash-free conversational messaging, working social/profile surfaces, and first-class offline Ekşi Şeyler reading. Restore the original oldschool droplet as the primary icon while offering text-free generated alternatives.

## Product decisions

- The entry-layout picker will not imitate the real row. It will render the real `EntryRowView` with deterministic sample data and a style override. A single renderer makes preview drift structurally impossible.
- App font size controls both type and nearby geometry. A clamped scale factor expands row padding, spacing, image size, and Settings row height without shrinking tap targets below 44 points.
- A successfully loaded entry page gets a new list identity, so SwiftUI starts it at the top. Refreshing the same page does not invent a page change.
- Re-tapping the already selected Home tab emits a reselection token. Home consumes it by closing transient UI, popping its navigation stack, and selecting Gündem regardless of the user-defined visual tab order.
- Message threads use pre-parsed plain text only. Incoming and outgoing messages are visually distinct bubbles in a bottom-anchored conversation; reply composition lives in a keyboard-safe bottom inset. This also removes the `NSAttributedString` HTML path identified in TestFlight crash build 13.
- Profile-connection pages use normal document requests. Authenticated Chrome verification showed the server markup is still `ul#follow-list`; the app-only failure is the forced AJAX header.
- The profile title is the sole username heading. The header retains avatar, bio, verification, badges, and stats. Pull-to-refresh force reloads profile and entries.
- The signed-in avatar is persisted as session presentation data and refreshed from the current user's profile when Settings appears.
- Ekşi Şeyler articles are encoded as native article data plus locally downloaded images. Saved articles appear beside saved topics in the offline library and open through the same native reader without a network dependency.
- The old flat dark-gray/green-droplet icon is the primary icon. GPT Image 2 alternatives remain word-free and are packaged as selectable alternate icons.

## Architecture

### Shared presentation policies

Pure, Sendable policies live under `Core/Presentation` so SwiftPM harness tests can cover:

- entry renderer style resolution;
- font-dependent entry and Settings geometry;
- list content identity for page/layout changes;
- main-tab reselection behavior;
- message bubble direction and alignment.

### Offline article storage

`OfflineSeylerStore` is a dedicated actor under `Core/Storage`. It stores one directory per source URL, with an atomic JSON manifest and a media directory keyed by normalized URLs. `SeylerArticleViewModel` tries saved content first, can save/delete the current network article, and resolves local image URLs when offline.

The existing background topic downloader remains unchanged. Article saves are bounded single-article transfers and run in an async task; every referenced image is fetched before the manifest is marked complete. A failed save preserves the prior valid copy.

### Accessibility

- Interactive controls keep at least 44x44-point targets.
- Bubble sender/direction, dates, save state, avatar, and icon selections have explicit labels/values.
- Font growth changes padding and wrapping rather than clipping.
- Message composer supports multiline input, keyboard focus, and a labeled send action.

## Validation

- Begin each behavior with a failing XCTest and mirrored core-harness assertion where the type is part of the SwiftPM core surface.
- Run the focused tests after each vertical slice, then the full core harness, repository contracts, simulator build/tests, widget build, SwiftLint, and App Store readiness checks.
- Install the release candidate on a simulator/device for smoke testing, then upload a higher marketing/build version to TestFlight and submit that build as the update only after App Store Connect processing succeeds.
