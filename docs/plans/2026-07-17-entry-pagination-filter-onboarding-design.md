# Entry Pagination and Filter Onboarding

## Goal

Make topic-page navigation unambiguous and teach the horizontal filter strip without permanently occupying screen space.

## Pagination

- Give every first, previous, next, and last control a 48×48 point circular touch target.
- Keep 14 points between controls within each directional pair.
- Place the current page in a separate capsule between the backward and forward groups.
- Disable both controls in a direction at the corresponding page boundary.
- Add explicit accessibility labels for every action and the page indicator.

## Filter onboarding

- Replace the small three-second hint with a first-use bottom sheet.
- Explain that the filter strip scrolls horizontally and that tapping a chip changes the active view.
- Mark onboarding complete only when the user taps “anladım” or dismisses the sheet.
- Use a new versioned preference key so people who missed the former auto-expiring hint see the improved onboarding once.

## Verification

- Keep pagination targeting and boundary rules in a Foundation-only policy covered by the core harness and XCTest.
- Verify the minimum touch target, spacing, grouping, page targets, disabled states, and one-time onboarding rule.
