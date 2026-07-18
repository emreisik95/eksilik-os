#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
installer="$repo_root/.github/scripts/install_verified_zip_tool.sh"
[[ -f "$installer" ]] || { echo "Missing tool installer: $installer" >&2; exit 127; }
tree_installer="$repo_root/.github/scripts/install_verified_zip_tree.sh"
[[ -f "$tree_installer" ]] || { echo "Missing tool tree installer: $tree_installer" >&2; exit 127; }

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

mkdir -p "$fixture_dir/tree-archive/tool/bin/resources"
# The fixture must evaluate this expression at runtime.
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' 'test -f "$(dirname "$0")/resources/preset.json"' \
    > "$fixture_dir/tree-archive/tool/bin/example-tool"
printf '%s\n' '{"preset":"verified"}' \
    > "$fixture_dir/tree-archive/tool/bin/resources/preset.json"
chmod +x "$fixture_dir/tree-archive/tool/bin/example-tool"
(cd "$fixture_dir/tree-archive" && zip -qr "$fixture_dir/tree.zip" .)
tree_checksum="$(shasum -a 256 "$fixture_dir/tree.zip" | awk '{print $1}')"

bash "$tree_installer" \
    "file://$fixture_dir/tree.zip" \
    "$tree_checksum" \
    "tool/bin" \
    "$fixture_dir/install/tree"

[[ -x "$fixture_dir/install/tree/example-tool" ]]
[[ -f "$fixture_dir/install/tree/resources/preset.json" ]]
"$fixture_dir/install/tree/example-tool"

echo "PASS: verified tool installer"
