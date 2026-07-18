# Existing App Store Listing Release Plan

**Goal:** Ship ek$ilik 2.0.0 as an update to the existing App Store listing (Apple ID `1454249683`) without losing the app's release history.

**Architecture:** Treat the existing App Store bundle identifier as the release contract. Keep app, widget, generated plist files, signing profiles, CI archive settings, and App Store Connect metadata aligned to that contract. Build on GitHub's macOS runner because the local Mac does not have the full Xcode application installed.

**Tech Stack:** SwiftUI, XcodeGen, shell validation, GitHub Actions, App Store Connect, `asc`, Xcode signing.

### Task 1: Lock the existing listing identity

**Files:**
- Modify: `.github/scripts/validate-app-store-readiness.sh`
- Modify: `project.yml`
- Regenerate: `EksilikApp-Info.plist`
- Regenerate: `EksilikWidget-Info.plist`

1. Add readiness assertions for the exact app and widget bundle identifiers, marketing version, and a build number newer than the historical build.
2. Run the validator and confirm it fails with the current `com.eksilik.app` identifiers.
3. Change the app to `emre.isik.Eksilik`, the widget to `emre.isik.Eksilik.widget`, the test bundle accordingly, and set build number `3`.
4. Regenerate the Xcode project and confirm readiness and core harness checks pass.

### Task 2: Produce App Store screenshots

**Artifacts:**
- Create: `/Users/emreisik/Downloads/eksilik-app-store-screenshots/final/*.png`
- Create: `/Users/emreisik/Downloads/eksilik-app-store-screenshots/eksilik-app-store-screenshots.zip`

1. Use the GPT Image 2 concept artwork as the campaign background language.
2. Compose six 1260x2736 portrait pages with accurate Turkish headlines and real app UI captures.
3. Verify every exported image for dimensions, text, safe areas, visual consistency, and truthful feature representation.
4. Replace the old App Store screenshots with the verified set.

### Task 3: Configure signing and release automation

**Files:**
- Create: `.github/workflows/app-store-release.yml`
- Create or modify: `ExportOptions.plist`
- Modify: repository secrets and variables (outside Git)

1. Reuse or create App Store Connect API credentials with the minimum practical role.
2. Ensure the existing app identifier and widget identifier have App Store distribution profiles.
3. Store the distribution certificate, profiles, and API credentials as encrypted GitHub Actions secrets.
4. Add a manually dispatched workflow that validates, archives, exports, and uploads build 3.

### Task 4: Upload and submit version 2.0.0

1. Run the release workflow and wait for App Store Connect processing.
2. Attach the processed build and the verified screenshot set to version 2.0.0.
3. Complete privacy, age rating, availability, review notes, and export-compliance checks.
4. Run submission preflight, resolve any errors, and submit for App Review.
