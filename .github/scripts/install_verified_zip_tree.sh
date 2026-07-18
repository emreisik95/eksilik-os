#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 <archive-url> <sha256> <directory-path-in-zip> <install-directory>" >&2
    exit 64
fi

archive_url="$1"
expected_sha="$2"
directory_path="$3"
install_directory="$4"

[[ "$expected_sha" =~ ^[0-9a-f]{64}$ ]] \
    || { echo "Expected SHA-256 must be 64 lowercase hexadecimal characters" >&2; exit 64; }

work_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/verified-tool-tree.XXXXXX")"
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

mkdir -p "$extract_path"
unzip -q "$archive_path" -d "$extract_path"
source_directory="$extract_path/$directory_path"
[[ -d "$source_directory" ]] \
    || { echo "Verified archive does not contain directory: $directory_path" >&2; exit 1; }
[[ ! -e "$install_directory" ]] \
    || { echo "Install destination already exists: $install_directory" >&2; exit 1; }

mkdir -p "$(dirname "$install_directory")"
cp -R "$source_directory" "$install_directory"

echo "Installed verified tool tree: $install_directory"
