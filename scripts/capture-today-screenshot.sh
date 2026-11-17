#!/bin/bash
# Recapture App Store 03-today only (featured birthmate with photo).
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_ID="${SIM_ID:-4625AE63-237E-42D5-BF3D-9BD554ACB589}"
BUNDLE="com.birthmate.app"
DERIVED="$ROOT/.derivedData"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/Birthmate.app"
OUT="$ROOT/AppStoreScreenshots"
MONTH="${SCREENSHOT_MONTH:-7}"
DAY="${SCREENSHOT_DAY:-29}"
TODAY_LOAD_WAIT="${SCREENSHOT_TODAY_LOAD_WAIT:-55}"

mkdir -p "$OUT"

echo "Building Birthmate (Debug)..."
xcodebuild -scheme Birthmate \
  -project "$ROOT/Birthmate.xcodeproj" \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  -derivedDataPath "$DERIVED" \
  build >/dev/null

xcrun simctl terminate "$SIM_ID" "$BUNDLE" 2>/dev/null || true

container="$(xcrun simctl get_app_container "$SIM_ID" "$BUNDLE" data 2>/dev/null || true)"
if [[ -z "$container" ]]; then
  xcrun simctl install "$SIM_ID" "$APP"
  container="$(xcrun simctl get_app_container "$SIM_ID" "$BUNDLE" data)"
fi

plist="$container/Library/Preferences/${BUNDLE}.plist"
mkdir -p "$(dirname "$plist")"
for pair in "birthmate_month:$MONTH" "birthmate_day:$DAY" "birthmate_launch_count:2"; do
  key="${pair%%:*}"
  value="${pair##*:}"
  if /usr/libexec/PlistBuddy -c "Print :$key" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist"
  else
    if [[ "$key" == "birthmate_has_seen_notification_prompt" ]]; then
      /usr/libexec/PlistBuddy -c "Add :$key bool $value" "$plist"
    else
      /usr/libexec/PlistBuddy -c "Add :$key integer $value" "$plist"
    fi
  fi
done
if /usr/libexec/PlistBuddy -c "Print :birthmate_has_seen_notification_prompt" "$plist" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Set :birthmate_has_seen_notification_prompt true" "$plist"
else
  /usr/libexec/PlistBuddy -c "Add :birthmate_has_seen_notification_prompt bool true" "$plist"
fi

echo "Launching Today (photo-required) — waiting ${TODAY_LOAD_WAIT}s..."
xcrun simctl launch "$SIM_ID" "$BUNDLE" \
  "-ScreenshotBirthdate=${MONTH}/${DAY}" \
  "-ScreenshotTab=today" \
  "-SkipNotificationPrompt" \
  "-ScreenshotRequireFeaturedPhoto" >/dev/null
sleep "$TODAY_LOAD_WAIT"

path="$OUT/03-today.png"
xcrun simctl io "$SIM_ID" screenshot "$path"
echo "Saved $path"