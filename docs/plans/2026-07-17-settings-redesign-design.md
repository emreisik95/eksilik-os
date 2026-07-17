# Settings Redesign

## Direction

The settings root becomes a calm, card-based control center instead of a long system form. A compact account card establishes context at the top. Five predictable groups follow in this order: appearance and reading, home, content, account, and advanced. Every row uses the same icon tile, title hierarchy, minimum touch height, optional current-value summary, and navigation treatment.

The native grouped-list approach was rejected because changing only colors and spacing would preserve the current visual clutter. A dashboard grid was also rejected because it hides labels, scales poorly with Dynamic Type, and adds navigation taps. A vertical stack of grouped cards remains scannable while still feeling substantially different from the current screen.

## Information architecture

- Appearance and reading: theme, entry layout, font size, filter presentation, app icon.
- Home: navigation style and tab order/visibility.
- Content: offline library and blocked-topic rules.
- Account: login when signed out; web preferences, tracking/blocking, and a confirmed logout when signed in.
- Advanced: server address on a dedicated screen.

App icon choices move to a focused picker rather than displaying three oversized icon rows on the root. The server URL also moves off the root so a long technical value does not dominate the page. Version information becomes a quiet dynamic footer instead of a full section.

## Interaction and accessibility

Rows have at least a 56-point height and descriptive SF Symbols. Font controls use separate 44-point decrement/increment buttons and clamp to the existing 10–24 range. Destructive logout requires confirmation. Navigation rows expose their selected value where useful, and toggles retain native semantics and the active theme tint.

## Verification

A Foundation-only presentation policy owns section order, item membership, signed-in variants, and font bounds. The core harness and XCTest validate those rules before SwiftUI implementation. CI then verifies the complete app with SwiftLint, an iPhone build, and the full test target.
