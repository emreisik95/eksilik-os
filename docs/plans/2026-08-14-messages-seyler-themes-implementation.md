# Messages, Page Wheel, Ekşi Şeyler, Themes, and iPad Icons Implementation Plan

**Goal:** Ship the completed feature set as a verified 2.0.2 internal TestFlight build.

**Architecture:** Pure request/pagination/parser/theme policies live in Core and receive focused tests. Services own network boundaries, view models own screen state, and SwiftUI views render observable state. Existing storage raw values and routes remain backward compatible.

**Tech stack:** Swift 5.9, SwiftUI, Kanna, XCTest, XcodeGen, GitHub Actions, Xcode Cloud, App Store Connect CLI.

### Task 1: Repair message document requests

**Files:**
- Modify: `Core/Network/EksiEndpoint.swift`
- Modify: `EksilikTests/Network/MessageRequestTests.swift`
- Modify: `CoreTestHarness/main.swift`

1. Add failing checks that message-list and conversation GETs omit the AJAX header while send-message remains a POST.
2. Implement document semantics for both GET endpoints.
3. Re-run request checks, parser fixtures, and the core harness.

### Task 2: Replace direct page entry with a swipeable wheel

**Files:**
- Modify: `Core/Presentation/PaginationSelectionPolicy.swift`
- Modify: `EksilikTests/Entry/PaginationSelectionPolicyTests.swift`
- Modify: `CoreTestHarness/main.swift`
- Modify: `Views/Entry/PaginationView.swift`

1. Add failing checks for clamped wheel selection and shortcut anchors.
2. Implement the pure selection helpers.
3. Replace the text-field/grid sheet with a wheel picker, shortcuts, and explicit confirmation.
4. Verify VoiceOver labels, touch targets, and boundary pages.

### Task 3: Make preferences reactive and Settings typography live

**Files:**
- Modify: `Core/Storage/UserPreferences.swift`
- Modify: `EksilikTests/Settings/UserPreferencesTests.swift`
- Modify: `Views/Settings/SettingsView.swift`

1. Add failing persistence and `objectWillChange` checks for font size and other formerly `@AppStorage` preferences.
2. Convert them to published, injected-defaults-backed properties with write-through persistence.
3. Apply the selected type scale to the Settings surface so its rows and preview respond in place.
4. Run targeted XCTest and verify navigation no longer triggers the update.

### Task 4: Implement the real Ekşi Şeyler feed

**Files:**
- Create: `Models/SeylerStory.swift`
- Create: `Core/Parsing/SeylerParser.swift`
- Create: `Core/Network/SeylerEndpoint.swift`
- Create: `Services/SeylerService.swift`
- Create: `ViewModels/SeylerFeedViewModel.swift`
- Create: `Views/Seyler/SeylerFeedView.swift`
- Create: `Views/Seyler/SeylerReaderView.swift`
- Create: `EksilikTests/Parsing/SeylerParserTests.swift`
- Modify: `Core/Presentation/HomeNavigationStyle.swift`
- Modify: `ViewModels/TopicListViewModel.swift`
- Modify: `Views/Home/HomeTabView.swift`
- Modify: `Core/Navigation/Route.swift`
- Modify: `Views/Home/TopicListView.swift`
- Modify: `Package.swift`
- Modify: `CoreTestHarness/main.swift`

1. Add failing parser fixtures for hero, content, mashup, lazy image, CSS background, duplicate, malformed, and external-link cases.
2. Implement endpoint and parser policies, then the URLSession service and view model.
3. Add the reorderable Home destination, category rail, editorial card layout, reader route, loading/error/empty states, and refresh.
4. Verify live output against current home and category pages without retaining user content.

The article destination must use native SwiftUI blocks, not a `WKWebView`. Message HTML must be
converted to plain text before it reaches SwiftUI rendering so HTML decoding cannot re-enter
AttributeGraph through WebKit on newer iOS versions.

### Task 5: Add ten themes with palette previews

**Files:**
- Modify: `Core/Theme/AppTheme.swift`
- Modify: `Views/Settings/ThemePickerView.swift`
- Create: `EksilikTests/Settings/AppThemeTests.swift`

1. Add failing checks for 15 stable unique cases, unchanged raw values 0–4, distinct palettes, and contrast thresholds.
2. Introduce palette tokens and append the ten new themes.
3. Redesign picker rows around three-swatch previews and concise theme descriptions.
4. Run theme and snapshot-adjacent build checks.

### Task 6: Fix alternate iPad icons and release validation

**Files:**
- Create: `Resources/AlternateIcons/AlternateIcon~ipad.png`
- Create: `Resources/AlternateIcons/AlternateIcon@2x~ipad.png`
- Create: `Resources/AlternateIcons/AlternateKlasik~ipad.png`
- Create: `Resources/AlternateIcons/AlternateKlasik@2x~ipad.png`
- Modify: `project.yml`
- Modify: `.github/scripts/validate-app-store-readiness.sh`
- Modify: `EksilikApp.xcodeproj/project.pbxproj` (generated)
- Modify: `EksilikApp-Info.plist` (generated)

1. Make the readiness test fail on missing 76/152 PNGs and missing `CFBundleIcons~ipad`.
2. Generate opaque iPad sizes from the existing icon artwork.
3. Add the mirrored iPad plist dictionary and regenerate the project.
4. Validate source files and the built `.app` bundle.

### Task 7: Verify and publish build 2.0.2

1. Determine the next unused App Store Connect build number and update app/widget/readiness configuration together.
2. Run core harness, XCTest with coverage, SwiftLint, repository contracts, App Store readiness, archive preflight, and secret/diff review.
3. Commit and push the branch; wait for every required GitHub check to succeed.
4. Trigger Xcode Cloud from the verified commit and wait for a successful archive/processing result.
5. Distribute only to the internal TestFlight group and report the exact build. Do not submit to App Review or merge without explicit authorization.
