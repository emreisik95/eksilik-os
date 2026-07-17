# Settings Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the crowded settings form with a cohesive card-based settings center without removing any currently reachable setting.

**Architecture:** A Foundation-only `SettingsPresentationPolicy` defines stable section and item order. `SettingsView` renders those descriptors into reusable SwiftUI card and row components, while focused subviews own app-icon and server editing.

**Tech Stack:** Swift 5.9, SwiftUI, UIKit alternate icons, XCTest, Swift Package core harness, XcodeGen.

### Task 1: Lock the information architecture with failing tests

**Files:**
- Modify: `CoreTestHarness/main.swift`
- Create: `EksilikTests/Settings/SettingsPresentationPolicyTests.swift`

1. Assert the five section kinds and their order for signed-out users.
2. Assert that signed-in and signed-out account items differ as intended.
3. Assert every root item appears exactly once.
4. Assert font decrement/increment clamps to 10–24.
5. Run `swift run EksilikCoreHarness` and confirm failure because the policy does not exist yet.

### Task 2: Add the presentation policy

**Files:**
- Create: `Core/Presentation/SettingsPresentationPolicy.swift`
- Modify: `Package.swift`

1. Define `SettingsSectionKind`, `SettingsItem`, and `SettingsSectionDescriptor`.
2. Implement `SettingsPresentationPolicy.sections(isLoggedIn:)` and bounded font adjustment.
3. Add the file to the core harness sources.
4. Run `swift run EksilikCoreHarness` and confirm the new checks pass.

### Task 3: Rebuild the settings root

**Files:**
- Replace: `Views/Settings/SettingsView.swift`

1. Replace `List` with a themed `ScrollView` and vertically grouped cards.
2. Add the account context card.
3. Render policy-driven section cards with uniform rows and dividers.
4. Add compact font controls and the filter-style toggle.
5. Add a logout confirmation dialog and a dynamic version footer.

### Task 4: Add focused pickers

**Files:**
- Create: `Views/Settings/AppIconPickerView.swift`
- Create: `Views/Settings/ServerSettingsView.swift`

1. Move alternate icon choices into a three-card adaptive grid.
2. Preserve the existing UIKit alternate-icon behavior and selected state.
3. Move base URL editing to a dedicated explanatory screen.

### Task 5: Verify and ship

**Files:**
- Verify all modified Swift and project files.

1. Generate the Xcode project.
2. Run the core harness, Swift parser, and whitespace checks.
3. Commit and push only the intended files; preserve `selfIdentity.plist`.
4. Wait for both GitHub Actions workflows to pass.
5. Sign the device artifact and install it on the paired iPhone 17 devices.
