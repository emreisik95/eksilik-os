#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bootstrap="$repo_root/.github/scripts/bootstrap_xcode_cloud.sh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/eksilik-xcode-cloud-bootstrap.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT

resolved="$fixture/repository/EksilikApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
mkdir -p "$(dirname "$resolved")"
printf 'name: Fixture\n' > "$fixture/repository/project.yml"
printf '{"pins":[],"version":2}\n' > "$resolved"

cat > "$fixture/fake-xcodegen" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

project=""
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --project)
            project="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

mkdir -p "$project/EksilikApp.xcodeproj"
: > "$project/EksilikApp.xcodeproj/project.pbxproj"
SCRIPT
chmod +x "$fixture/fake-xcodegen"

XCODEGEN_BINARY="$fixture/fake-xcodegen" \
    bash "$bootstrap" "$fixture/repository"

grep -Fq '"version":2' "$resolved" \
    || { echo "Xcode Cloud bootstrap did not preserve the resolved package graph" >&2; exit 1; }

echo "PASS: Xcode Cloud bootstrap contract"
