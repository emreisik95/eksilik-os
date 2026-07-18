#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <file-url> <sha256> <install-path>" >&2
    exit 64
fi

file_url="$1"
expected_sha="$2"
install_path="$3"

[[ "$expected_sha" =~ ^[0-9a-f]{64}$ ]] \
    || { echo "Expected SHA-256 must be 64 lowercase hexadecimal characters" >&2; exit 64; }

work_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/verified-file.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
download_path="$work_dir/download"

curl --fail --silent --show-error --location \
    --proto '=https,file' \
    --tlsv1.2 \
    "$file_url" \
    --output "$download_path"

actual_sha="$(shasum -a 256 "$download_path" | awk '{print $1}')"
if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo "SHA-256 verification failed: expected $expected_sha, got $actual_sha" >&2
    exit 1
fi

mkdir -p "$(dirname "$install_path")"
install -m 0755 "$download_path" "$install_path"

echo "Installed verified file: $install_path"
