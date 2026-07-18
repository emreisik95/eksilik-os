#!/usr/bin/env bash
set -euo pipefail

fail() {
    echo "App Store readiness failed: $1" >&2
    exit 1
}

grep -Eq '^[[:space:]]+PRODUCT_BUNDLE_IDENTIFIER: emre\.isik\.Eksilik$' project.yml \
    || fail "app bundle identifier must match the existing App Store listing"
grep -Eq '^[[:space:]]+PRODUCT_BUNDLE_IDENTIFIER: emre\.isik\.Eksilik\.widget$' project.yml \
    || fail "widget bundle identifier must be nested under the existing App Store listing"
grep -Fq '= "emre.isik.Eksilik"' .github/workflows/device-build.yml \
    || fail "device artifact verification must use the existing App Store bundle identifier"
[[ "$(grep -Ec '^[[:space:]]+MARKETING_VERSION: "2\.0\.1"$' project.yml)" -eq 2 ]] \
    || fail "app and widget marketing versions must be 2.0.1"
[[ "$(grep -Ec '^[[:space:]]+CURRENT_PROJECT_VERSION: "8"$' project.yml)" -eq 2 ]] \
    || fail "app and widget build numbers must be 8"
[[ "$(grep -Ec '^[[:space:]]+TARGETED_DEVICE_FAMILY: "1,2"$' project.yml)" -eq 2 ]] \
    || fail "app and widget must preserve the existing iPhone and iPad device families"
grep -Fq 'CFBundleDisplayName: "ek$ilik"' project.yml \
    || fail "widget display name is required by App Store validation"
for orientation in \
    UIInterfaceOrientationPortrait \
    UIInterfaceOrientationPortraitUpsideDown \
    UIInterfaceOrientationLandscapeLeft \
    UIInterfaceOrientationLandscapeRight; do
    grep -Fq -- "- $orientation" project.yml \
        || fail "iPad multitasking orientation $orientation is missing"
done
[[ "$(grep -Ec '^[[:space:]]+CODE_SIGN_IDENTITY: "Apple Distribution"$' project.yml)" -eq 2 ]] \
    || fail "release targets must use the Apple Distribution certificate"
[[ "$(grep -Ec '^[[:space:]]+DEVELOPMENT_TEAM: "235UP83FJ4"$' project.yml)" -eq 2 ]] \
    || fail "release signing team must match the existing App Store account"
grep -Fq 'PROVISIONING_PROFILE_SPECIFIER: "Eksilik App Store AppGroups 2026"' project.yml \
    || fail "app App Store provisioning profile is not configured"
grep -Fq 'PROVISIONING_PROFILE_SPECIFIER: "Eksilik Widget App Store AppGroups 2026"' project.yml \
    || fail "widget App Store provisioning profile is not configured"
[[ "$(grep -Ec '^[[:space:]]+CODE_SIGN_ENTITLEMENTS: Eksilik(App|Widget)\.entitlements$' project.yml)" -eq 2 ]] \
    || fail "app and widget App Group entitlements are not configured"
for entitlements in EksilikApp.entitlements EksilikWidget.entitlements; do
    [[ -f "$entitlements" ]] || fail "$entitlements is missing"
    /usr/libexec/PlistBuddy -c 'Print :com.apple.security.application-groups:0' "$entitlements" 2>/dev/null \
        | grep -Fxq 'group.emre.isik.Eksilik' \
        || fail "$entitlements must use the shared Eksilik App Group"
done
[[ -f ExportOptions.plist ]] || fail "ExportOptions.plist is missing"
[[ -f .github/workflows/app-store-release.yml ]] || fail "App Store release workflow is missing"
grep -Fq 'runs-on: macos-26' .github/workflows/app-store-release.yml \
    || fail "App Store releases must use Xcode 26 or later"

if [[ ! -f EksilikApp-Info.plist || ! -f EksilikWidget-Info.plist ]]; then
    xcodegen generate >/dev/null
fi

app_version="$(plutil -extract CFBundleShortVersionString raw EksilikApp-Info.plist)"
app_build="$(plutil -extract CFBundleVersion raw EksilikApp-Info.plist)"
widget_version="$(plutil -extract CFBundleShortVersionString raw EksilikWidget-Info.plist)"
widget_build="$(plutil -extract CFBundleVersion raw EksilikWidget-Info.plist)"

[[ "$app_version" == '$(MARKETING_VERSION)' ]] || fail "app version must inherit MARKETING_VERSION"
[[ "$app_build" == '$(CURRENT_PROJECT_VERSION)' ]] || fail "app build must inherit CURRENT_PROJECT_VERSION"
[[ "$widget_version" == '$(MARKETING_VERSION)' ]] || fail "widget version must inherit MARKETING_VERSION"
[[ "$widget_build" == '$(CURRENT_PROJECT_VERSION)' ]] || fail "widget build must inherit CURRENT_PROJECT_VERSION"

[[ "$(plutil -extract ITSAppUsesNonExemptEncryption raw EksilikApp-Info.plist 2>/dev/null || true)" == "false" ]] \
    || fail "encryption exemption must be declared"

privacy_manifest="Resources/PrivacyInfo.xcprivacy"
[[ -f "$privacy_manifest" ]] || fail "PrivacyInfo.xcprivacy is missing"
[[ "$(plutil -extract NSPrivacyTracking raw "$privacy_manifest")" == "false" ]] \
    || fail "privacy manifest tracking declaration is missing"
plutil -p "$privacy_manifest" | grep -q 'NSPrivacyAccessedAPICategoryUserDefaults' \
    || fail "UserDefaults required-reason declaration is missing"
plutil -p "$privacy_manifest" | grep -q 'CA92.1' \
    || fail "UserDefaults reason CA92.1 is missing"

[[ -s PRIVACY.md ]] || fail "public privacy policy is missing"
[[ -s SUPPORT.md ]] || fail "public support document is missing"
grep -q 'Button(L10n.Entry.reportEntry' Views/Entry/EntryRowView.swift \
    || fail "entry reporting action is missing"
grep -q 'func blockUser(authorId:' Services/EntryService.swift \
    || fail "functional author blocking is missing"

for family in AlternateIcon AlternateKlasik; do
    for scale in 1 2 3; do
        file="Resources/AlternateIcons/${family}@${scale}x.png"
        expected=$((60 * scale))
        width="$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
        height="$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
        alpha="$(sips -g hasAlpha "$file" 2>/dev/null | awk '/hasAlpha/ {print $2}')"
        [[ "$width" == "$expected" && "$height" == "$expected" ]] \
            || fail "$file must be ${expected}x${expected}"
        [[ "$alpha" == "no" ]] || fail "$file must not contain transparency"
    done
done

echo "PASS: App Store readiness checks"
