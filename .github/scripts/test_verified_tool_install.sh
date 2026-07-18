#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
installer="$repo_root/.github/scripts/install_verified_zip_tool.sh"
[[ -f "$installer" ]] || { echo "Missing tool installer: $installer" >&2; exit 127; }

fixture_dir="$(mktemp -d "${TMPDIR:-/tmp}/eksilik-tool-test.XXXXXX")"
trap 'rm -rf "$fixture_dir"' EXIT

mkdir -p "$fixture_dir/archive/bin" "$fixture_dir/install"
printf '%s\n' '#!/usr/bin/env bash' 'echo verified-tool' > "$fixture_dir/archive/bin/example-tool"
chmod +x "$fixture_dir/archive/bin/example-tool"
(cd "$fixture_dir/archive" && zip -qr "$fixture_dir/example.zip" .)
checksum="$(shasum -a 256 "$fixture_dir/example.zip" | awk '{print $1}')"

bash "$installer" \
    "file://$fixture_dir/example.zip" \
    "$checksum" \
    "bin/example-tool" \
    "$fixture_dir/install/example-tool"

[[ -x "$fixture_dir/install/example-tool" ]]
[[ "$("$fixture_dir/install/example-tool")" == "verified-tool" ]]

if bash "$installer" \
    "file://$fixture_dir/example.zip" \
    "0000000000000000000000000000000000000000000000000000000000000000" \
    "bin/example-tool" \
    "$fixture_dir/install/rejected-tool" > "$fixture_dir/rejected.out" 2>&1; then
    echo "Expected an invalid digest to fail" >&2
    exit 1
fi
grep -Fq 'SHA-256 verification failed' "$fixture_dir/rejected.out"
[[ ! -e "$fixture_dir/install/rejected-tool" ]]

echo "PASS: verified tool installer"

