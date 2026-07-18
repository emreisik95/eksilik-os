#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 <archive-url> <sha256> <binary-path-in-zip> <install-path>" >&2
    exit 64
fi

archive_url="$1"
expected_sha="$2"
binary_path="$3"
install_path="$4"

[[ "$expected_sha" =~ ^[0-9a-f]{64}$ ]] \
    || { echo "Expected SHA-256 must be 64 lowercase hexadecimal characters" >&2; exit 64; }

work_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/verified-tool.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
archive_path="$work_dir/tool.zip"
extract_path="$work_dir/extracted"

curl --fail --silent --show-error --location \
    --proto '=https,file' \
    --tlsv1.2 \
    "$archive_url" \
    --output "$archive_path"

actual_sha="$(shasum -a 256 "$archive_path" | awk '{print $1}')"
if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo "SHA-256 verification failed: expected $expected_sha, got $actual_sha" >&2
    exit 1
fi

mkdir -p "$extract_path" "$(dirname "$install_path")"
unzip -q "$archive_path" -d "$extract_path"
[[ -f "$extract_path/$binary_path" ]] \
    || { echo "Verified archive does not contain: $binary_path" >&2; exit 1; }
install -m 0755 "$extract_path/$binary_path" "$install_path"

echo "Installed verified tool: $install_path"

