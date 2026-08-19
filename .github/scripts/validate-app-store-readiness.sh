#!/usr/bin/env bash
set -euo pipefail

fail() {
    echo "App Store readiness failed: $1" >&2
    exit 1
}

app_marketing_version="$(ruby -ryaml -e 'puts YAML.load_file("project.yml").dig("targets", "EksilikApp", "settings", "base", "MARKETING_VERSION")')"
widget_marketing_version="$(ruby -ryaml -e 'puts YAML.load_file("project.yml").dig("targets", "EksilikWidget", "settings", "base", "MARKETING_VERSION")')"
app_build_number="$(ruby -ryaml -e 'puts YAML.load_file("project.yml").dig("targets", "EksilikApp", "settings", "base", "CURRENT_PROJECT_VERSION")')"
widget_build_number="$(ruby -ryaml -e 'puts YAML.load_file("project.yml").dig("targets", "EksilikWidget", "settings", "base", "CURRENT_PROJECT_VERSION")')"

[[ -n "$app_marketing_version" && "$app_marketing_version" == "$widget_marketing_version" ]] \
    || fail "app and widget marketing versions must match"
[[ -n "$app_build_number" && "$app_build_number" == "$widget_build_number" ]] \
    || fail "app and widget build numbers must match"
[[ -z "${RELEASE_VERSION:-}" || "$RELEASE_VERSION" == "$app_marketing_version" ]] \
    || fail "release input version must match project.yml"
[[ -z "${RELEASE_BUILD_NUMBER:-}" || "$RELEASE_BUILD_NUMBER" == "$app_build_number" ]] \
    || fail "release input build number must match project.yml"

grep -Eq '^[[:space:]]+PRODUCT_BUNDLE_IDENTIFIER: emre\.isik\.Eksilik$' project.yml \
    || fail "app bundle identifier must match the existing App Store listing"
grep -Eq '^[[:space:]]+PRODUCT_BUNDLE_IDENTIFIER: emre\.isik\.Eksilik\.widget$' project.yml \
    || fail "widget bundle identifier must be nested under the existing App Store listing"
grep -Fq '= "emre.isik.Eksilik"' .github/workflows/device-build.yml \
    || fail "device artifact verification must use the existing App Store bundle identifier"
[[ "$(grep -Ec "^[[:space:]]+MARKETING_VERSION: \"${app_marketing_version//./\\.}\"$" project.yml)" -eq 2 ]] \
    || fail "app and widget marketing versions must be declared explicitly"
[[ "$(grep -Ec "^[[:space:]]+CURRENT_PROJECT_VERSION: \"${app_build_number}\"$" project.yml)" -eq 2 ]] \
    || fail "app and widget build numbers must be declared explicitly"
[[ "$(grep -Ec '^[[:space:]]+TARGETED_DEVICE_FAMILY: "1,2"$' project.yml)" -eq 2 ]] \
    || fail "app and widget must preserve the existing iPhone and iPad device families"
# shellcheck disable=SC2016
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
grep -Fq "default: \"$app_marketing_version\"" .github/workflows/app-store-release.yml \
    || fail "release workflow version must match project.yml"
grep -Fq "default: \"$app_build_number\"" .github/workflows/app-store-release.yml \
    || fail "release workflow build number must match project.yml"

if [[ ! -f EksilikApp-Info.plist || ! -f EksilikWidget-Info.plist ]]; then
    xcodegen generate >/dev/null
fi

app_version="$(plutil -extract CFBundleShortVersionString raw EksilikApp-Info.plist)"
app_build="$(plutil -extract CFBundleVersion raw EksilikApp-Info.plist)"
widget_version="$(plutil -extract CFBundleShortVersionString raw EksilikWidget-Info.plist)"
widget_build="$(plutil -extract CFBundleVersion raw EksilikWidget-Info.plist)"

# These are literal Xcode build-setting placeholders.
# shellcheck disable=SC2016
[[ "$app_version" == '$(MARKETING_VERSION)' ]] || fail "app version must inherit MARKETING_VERSION"
# shellcheck disable=SC2016
[[ "$app_build" == '$(CURRENT_PROJECT_VERSION)' ]] || fail "app build must inherit CURRENT_PROJECT_VERSION"
# shellcheck disable=SC2016
[[ "$widget_version" == '$(MARKETING_VERSION)' ]] || fail "widget version must inherit MARKETING_VERSION"
# shellcheck disable=SC2016
[[ "$widget_build" == '$(CURRENT_PROJECT_VERSION)' ]] || fail "widget build must inherit CURRENT_PROJECT_VERSION"

[[ "$(plutil -extract ITSAppUsesNonExemptEncryption raw EksilikApp-Info.plist 2>/dev/null || true)" == "false" ]] \
    || fail "encryption exemption must be declared"

privacy_manifest="Resources/PrivacyInfo.xcprivacy"
[[ -f "$privacy_manifest" ]] || fail "PrivacyInfo.xcprivacy is missing"
ruby -ryaml -e '
  resources = YAML.load_file("project.yml").dig("targets", "EksilikWidget", "resources") || []
  exit(resources.any? { |resource| resource["path"] == "EksilikWidget/PrivacyInfo.xcprivacy" } ? 0 : 1)
' || fail "widget target must bundle PrivacyInfo.xcprivacy"
cmp -s "$privacy_manifest" EksilikWidget/PrivacyInfo.xcprivacy \
    || fail "app and widget privacy manifests must stay identical"
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

primary_icon="Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
primary_width="$(sips -g pixelWidth "$primary_icon" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
primary_height="$(sips -g pixelHeight "$primary_icon" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
primary_alpha="$(sips -g hasAlpha "$primary_icon" 2>/dev/null | awk '/hasAlpha/ {print $2}')"
[[ "$primary_width" == "1024" && "$primary_height" == "1024" ]] \
    || fail "$primary_icon must be 1024x1024"
[[ "$primary_alpha" == "no" ]] || fail "$primary_icon must not contain transparency"

for family in \
    AlternateIcon \
    AlternateKlasik \
    AlternateNoir \
    AlternateAurora \
    AlternateDepth \
    AlternateForest; do
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

    for ipad_file in \
        "Resources/AlternateIcons/${family}~ipad.png:76" \
        "Resources/AlternateIcons/${family}@2x~ipad.png:152"; do
        file="${ipad_file%:*}"
        expected="${ipad_file##*:}"
        [[ -f "$file" ]] || fail "$file is missing"
        width="$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
        height="$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
        alpha="$(sips -g hasAlpha "$file" 2>/dev/null | awk '/hasAlpha/ {print $2}')"
        [[ "$width" == "$expected" && "$height" == "$expected" ]] \
            || fail "$file must be ${expected}x${expected}"
        [[ "$alpha" == "no" ]] || fail "$file must not contain transparency"
    done

    /usr/libexec/PlistBuddy \
        -c "Print :CFBundleIcons:CFBundleAlternateIcons:${family}:CFBundleIconFiles:0" \
        EksilikApp-Info.plist 2>/dev/null | grep -Fxq "$family" \
        || fail "CFBundleIcons must reference $family"
    /usr/libexec/PlistBuddy \
        -c "Print :CFBundleIcons~ipad:CFBundleAlternateIcons:${family}:CFBundleIconFiles:0" \
        EksilikApp-Info.plist 2>/dev/null | grep -Fxq "$family" \
        || fail "CFBundleIcons~ipad must reference $family"
done

release_metadata="metadata/version/$app_marketing_version/tr.json"
[[ -f "$release_metadata" ]] || fail "Turkish $app_marketing_version release metadata is missing"
jq -e '.whatsNew | length > 0 and length <= 4000' "$release_metadata" >/dev/null \
    || fail "$app_marketing_version What's New must be between 1 and 4000 characters"
jq -e '.promotionalText | length <= 170' "$release_metadata" >/dev/null \
    || fail "$app_marketing_version promotional text must not exceed 170 characters"

echo "PASS: App Store readiness checks"
