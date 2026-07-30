#!/bin/bash
# Build, seed Simulator state, and capture a full App Store screenshot set.
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Users/osagieobaretin/Downloads/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_ID="${SIM_ID:-57671833-C49B-4873-AE2E-63D80F929C1A}"
BUNDLE="com.birthmate.app"
DERIVED="$ROOT/.derivedData"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/Birthmate.app"
OUT="$ROOT/AppStoreScreenshots"
MONTH="${SCREENSHOT_MONTH:-7}"
DAY="${SCREENSHOT_DAY:-29}"
LOAD_WAIT="${SCREENSHOT_LOAD_WAIT:-12}"

mkdir -p "$OUT"

shot() {
  local name="$1"
  local path="$OUT/$name.png"
  xcrun simctl io "$SIM_ID" screenshot "$path"
  echo "Saved $path"
}

terminate_app() {
  xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true
}

prefs_plist() {
  xcrun simctl get_app_container "$SIM_ID" "$BUNDLE" data 2>/dev/null
}

set_pref_int() {
  local key="$1"
  local value="$2"
  local plist="$3/Library/Preferences/${BUNDLE}.plist"
  mkdir -p "$(dirname "$plist")"
  if /usr/libexec/PlistBuddy -c "Print :$key" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist"
  else
    /usr/libexec/PlistBuddy -c "Add :$key integer $value" "$plist"
  fi
}

set_pref_bool() {
  local key="$1"
  local value="$2"
  local plist="$3/Library/Preferences/${BUNDLE}.plist"
  mkdir -p "$(dirname "$plist")"
  if /usr/libexec/PlistBuddy -c "Print :$key" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist"
  else
    /usr/libexec/PlistBuddy -c "Add :$key bool $value" "$plist"
  fi
}

seed_birthdate() {
  local container
  container="$(prefs_plist)"
  set_pref_int birthmate_month "$MONTH" "$container"
  set_pref_int birthmate_day "$DAY" "$container"
}

seed_welcome_seen() {
  local seen="$1"
  local container
  container="$(prefs_plist)"
  set_pref_bool birthmate_has_seen_welcome_tips "$seen" "$container"
}

launch_with_args() {
  terminate_app
  xcrun simctl launch "$SIM_ID" "$BUNDLE" "$@" >/dev/null
}

echo "Building Birthmate (Debug)..."
xcodebuild -scheme Birthmate \
  -project "$ROOT/Birthmate.xcodeproj" \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -derivedDataPath "$DERIVED" \
  build >/dev/null

echo "Fresh install for onboarding screenshot..."
xcrun simctl uninstall "$SIM_ID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_ID" "$APP"
launch_with_args
sleep 3
shot "02-onboarding"

echo "Seeding birth date ($MONTH/$DAY) and skipping welcome..."
seed_birthdate
seed_welcome_seen true

capture_tab() {
  local slug="$1"
  local arg="$2"
  echo "Capturing $slug..."
  launch_with_args "-SkipWelcomeTips" "-ScreenshotTab=$arg"
  sleep "$LOAD_WAIT"
  shot "$slug"
}

capture_tab "03-today" "today"
capture_tab "04-birthmates" "birthmates"
capture_tab "05-history" "history"
capture_tab "06-settings" "settings"
capture_tab "07-circle" "circle"

echo "Capturing welcome sheet..."
seed_welcome_seen false
launch_with_args "-ShowWelcomeTips"
sleep 3
shot "08-welcome"

echo ""
echo "Done. Screenshots in $OUT"
ls -1 "$OUT"/*.png
