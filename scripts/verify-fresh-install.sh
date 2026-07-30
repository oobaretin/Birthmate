#!/bin/bash
# Fresh-install verification for Birthmate (Simulator).
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Users/osagieobaretin/Downloads/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_ID="${SIM_ID:-57671833-C49B-4873-AE2E-63D80F929C1A}"
BUNDLE="com.birthmate.app"
DERIVED="$ROOT/.derivedData"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/Birthmate.app"
LOG="$ROOT/.cursor/checklist-fresh-install.log"

mkdir -p "$(dirname "$LOG")"
: > "$LOG"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

log "Building Birthmate..."
xcodebuild -scheme Birthmate \
  -project "$ROOT/Birthmate.xcodeproj" \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -derivedDataPath "$DERIVED" \
  build >> "$LOG" 2>&1

log "Uninstalling existing app (fresh install)..."
xcrun simctl uninstall "$SIM_ID" "$BUNDLE" 2>/dev/null || true

log "Installing app..."
xcrun simctl install "$SIM_ID" "$APP"

log "Launching app..."
PID=$(xcrun simctl launch "$SIM_ID" "$BUNDLE" | awk '{print $2}')
log "Launched pid=$PID"

sleep 4

if xcrun simctl spawn "$SIM_ID" launchctl list 2>/dev/null | grep -q "com.birthmate.app"; then
  log "PASS: App registered and running after 4s (no immediate crash)."
else
  log "FAIL: App not running after launch — possible crash."
  exit 1
fi

log "Fresh-install smoke test complete."
