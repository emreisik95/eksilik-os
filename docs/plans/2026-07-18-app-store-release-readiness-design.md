# App Store Release Readiness Design

**Goal:** Prepare ek$ilik 2.0.0 for an App Store submission without changing its core product behavior.

## Scope

- Make the archive inherit its marketing version and build number from Xcode settings.
- Declare export-compliance exemption and required-reason API usage.
- Publish an accurate privacy policy and support path.
- Surface privacy and support links in Settings.
- Give users visible report and functional author-block actions for user-generated content.
- Normalize alternate icon files to App Store-safe sizes with no alpha channel.

## Privacy model

The developer does not operate an analytics or data-collection backend. Preferences, cookies, and offline topics remain on the device. Network requests and optional account authentication go directly to the user-selected Ekşi Sözlük server. The App Store privacy label can therefore state that the developer collects no data, while the privacy policy clearly identifies the third-party service interaction.

## Release strategy

All readiness changes are isolated on `codex/app-store-release`, validated by the core harness and a deterministic release-readiness script, merged into `main`, and archived only from that merged commit. App Store Connect metadata will use Turkish as the primary locale, version 2.0.0, and manual release after approval unless Apple requires a different existing app-record configuration.
