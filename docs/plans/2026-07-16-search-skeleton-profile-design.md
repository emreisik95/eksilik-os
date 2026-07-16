# Search, Full-Screen Skeleton, and Profile Connections Design

## Goals

- Replace the compact system search presentation with a large, purpose-built search screen.
- Keep topic, author, entry-number, channel, loading, empty, and error states visually distinct.
- Make every skeleton cover the available viewport on tall phones instead of ending after a fixed number of rows.
- Make profile follower and following counts tappable and show the corresponding people.

## Search experience

The search tab remains a `NavigationStack`, but the content becomes a full-screen `ScrollView` with a large custom search field at the top. The field uses a minimum 52-point height, a clear action, explicit focus, and the existing query routing rules. An empty query shows a short explanation and channel discovery cards. A one-character query explains that at least two characters are required. Active requests show a dedicated full-screen search skeleton. Successful autocomplete results are split into large topic and author cards, while an empty response and a network error each receive their own recovery state.

The view model continues cancelling stale searches. A small presentation policy owns query normalization and screen-state decisions so these rules can be tested without rendering SwiftUI. The network format and existing `Route` navigation remain unchanged.

## Skeleton layout

The blank area is caused by fixed placeholder counts: five entry/profile rows, eight channel rows, and twelve topic rows cannot cover every viewport. `SkeletonLayout` will calculate the required row count from viewport height, occupied header height, estimated row height, a minimum count, and one overscan row. Each skeleton view will read its available size with `GeometryReader`, use the calculated count, fill the available width and height, and paint the current theme background behind the entire placeholder surface.

The existing deterministic bar-width patterns stay intact, preventing the earlier shrinking/growing effect. Animation remains opacity-only and respects the stable geometry.

## Profile connections

The profile parser will retain the real follower and following links found around the existing count elements. Tapping either stat opens a reusable people list. The service fetches that captured link, and a parser extracts profile links and displayed names while preserving order and removing duplicates. Loading, empty, and retry states use the same full-screen visual language as the rest of the app. If the site omits or hides a link, the corresponding count remains visible but is not presented as an actionable control.

## Verification

Pure layout, search-state, link, and people-list parsing rules will be covered in the macOS core harness and XCTest. The generated Xcode project will be built for a generic iOS device through GitHub Actions. The resulting app will be locally signed, verified recursively, installed on the paired iPhone 17, launched, and checked for a live process.
