# Widget and Entry Composer Design

## Goal

Ship the next ek$ilik build to TestFlight with two focused improvements: useful home-screen widgets for fast access to gündem, debe, bugün and the signed-in takip feed; and a distraction-free entry composer that makes formatting, drafting and submission comfortable on iPhone and iPad.

The App Store 2.0.0 submission remains untouched. This work uses a separate branch and will increment the build/version only when the current review is complete and the TestFlight release is requested.

## Widget architecture

The existing configurable topic widget stays, but its data contract moves into shared app/extension code. Public sources are refreshed by the extension. The signed-in takip source is fetched by the main app using its existing authenticated HTTP client and stored as a small Codable snapshot in an App Group container. The widget reads that last-good snapshot; authentication cookies never leave the app process.

Two widgets are exposed:

- **akış:** configurable source, theme and optional username; shows tappable rows for gündem, bugün, debe, takip and user pages.
- **kısayollar:** a compact native grid for gündem, takip, debe and bugün. Each tile deep-links to the matching native list inside the app.

The app refreshes the shared snapshot whenever one of the supported home feeds loads. The widget shows an honest empty/offline state and the snapshot update time. Stable link-based item identifiers prevent row churn.

## Entry composer UX

The composer becomes a focused destination with the tab bar hidden. Navigation uses an icon-only back button, a centered topic title and a prominent trailing send control. The editor owns the visual hierarchy: a clear placeholder, readable type, generous padding and a lightweight character count/save indicator.

A keyboard-adjacent horizontal tool row opens small input sheets for bkz, hede, hidden text, spoiler and links. Insertions happen at the current cursor selection rather than at the end of the entry. Drafts are saved automatically per topic and restored when the composer reopens. Successful submission clears the draft; failed submission leaves content intact and shows an actionable error. Double-submit is prevented.

## Error handling and testing

Pure formatting, cursor insertion, snapshot persistence and parser behavior are covered by XCTest before production code is added. Widget network failures fall back to cached/public placeholder content. App Group access failure falls back to standard storage in tests only, never to shared auth data. UI state derives from explicit loading/submitting flags so the editor is never replaced by a full-screen spinner after typing starts.

Verification includes the existing readiness script, generated project checks, XCTest/unsigned device build in GitHub CI and manual TestFlight smoke checks for widget configuration, deep links, draft restore, formatting at selection and successful/failed submission.
