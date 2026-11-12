#!/bin/bash
# Capture Simulator screenshots for App Store listing.
# Run after onboarding, or complete onboarding manually when prompted.
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_ID="${SIM_ID:-4625AE63-237E-42D5-BF3D-9BD554ACB589}"
OUT="$ROOT/AppStoreScreenshots"
mkdir -p "$OUT"

shot() {
  local name="$1"
  local path="$OUT/$name.png"
  xcrun simctl io "$SIM_ID" screenshot "$path"
  echo "Saved $path"
}

echo "Capturing current Simulator screen..."
shot "01-current-screen"

echo ""
echo "For a full set, manually navigate and re-run:"
echo "  ./scripts/capture-app-store-screenshots.sh"
echo ""
echo "Suggested shots (rename after capture):"
echo "  02-onboarding.png   — month/day picker"
echo "  03-today.png        — Today tab"
echo "  04-birthmates.png   — Birthmates tab"
echo "  05-history.png      — History tab"
echo "  06-welcome.png      — welcome sheet (reset birthmate_has_seen_welcome_tips)"
