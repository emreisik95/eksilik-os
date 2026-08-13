#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-${CI_PRIMARY_REPOSITORY_PATH:-$(git rev-parse --show-toplevel)}}"
xcodegen_binary="${XCODEGEN_BINARY:-}"

if [[ -z "$xcodegen_binary" ]]; then
    xcodegen_url="https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.artifactbundle.zip"
    xcodegen_sha256="ef6d0a23bfb7393387f98e321ffd78a487231172e2e78c48d3c26275c263fd0c"
    archive_directory="xcodegen.artifactbundle/xcodegen-2.46.0-macosx/bin"
    tools_directory="${CI_DERIVED_DATA_PATH:-${TMPDIR:-/tmp}}/eksilik-xcode-cloud-tools"

    bash "$repo_root/.github/scripts/install_verified_zip_tree.sh" \
        "$xcodegen_url" \
        "$xcodegen_sha256" \
        "$archive_directory" \
        "$tools_directory"
    xcodegen_binary="$tools_directory/xcodegen"
fi

[[ -x "$xcodegen_binary" ]] || {
    echo "Xcode Cloud bootstrap failed: XcodeGen is unavailable" >&2
    exit 1
}

"$xcodegen_binary" generate \
    --spec "$repo_root/project.yml" \
    --project "$repo_root"

[[ -f "$repo_root/EksilikApp.xcodeproj/project.pbxproj" ]] || {
    echo "Xcode Cloud bootstrap failed: generated project is missing" >&2
    exit 1
}

echo "Xcode Cloud project generated with verified XcodeGen 2.46.0"
