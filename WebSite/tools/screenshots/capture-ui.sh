#!/bin/bash
# capture-ui.sh — drives the app with UI automation (WebsiteScreenshotTests) and exports the
# screenshots for every sheet and sub-screen. WebSite20260919v1-WebSite.md Phase W6.5.
# Usage: capture-ui.sh [iphone|mac] [TestName]   (default: iphone, all flows)
set -euo pipefail

device="${1:-iphone}"
only="${2:-}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
assets="$repo/WebSite/content/en/_assets"
sim_name="NoteBytez Screenshots (iPhone 17 Pro)"
work="$(mktemp -d)"

notes="$(node -e 'const fs=require("fs"),p=require("path");const d=process.argv[1];console.log(JSON.stringify(Object.fromEntries(fs.readdirSync(d).filter(f=>f.endsWith(".md")).map(f=>[f,fs.readFileSync(p.join(d,f),"utf8")]))))' "$here/seedLibrary")"

if [ "$device" = "iphone" ]; then
  udid="$(xcrun simctl list devices -j | node -e 'const d=JSON.parse(require("fs").readFileSync(0));console.log(Object.values(d.devices).flat().find(v=>v.name===process.argv[1]&&v.isAvailable)?.udid??"")' "$sim_name")"
  [ -n "$udid" ] || { echo "Run capture.sh once first to create the '$sim_name' simulator." >&2; exit 1; }
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
    --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --operatorName ""
  destination="id=$udid"
else
  destination="platform=macOS"
fi
target="NoteBytezUITests/WebsiteScreenshotTests${only:+/$only}"

for appearance in ${APPEARANCES:-light dark}; do
  echo "▶ $device / $appearance"
  result="$work/$appearance.xcresult"
  TEST_RUNNER_WEBSITE_SCREENSHOTS=1 TEST_RUNNER_WEBSITE_APPEARANCE="$appearance" TEST_RUNNER_WEBSITE_SEED_NOTES="$notes" \
    xcodebuild test -quiet -project "$repo/NoteBytez.xcodeproj" -scheme NoteBytez -destination "$destination" \
    -only-testing:"$target" -resultBundlePath "$result" >"$work/$appearance.log" 2>&1 || echo "  (some steps failed; see $work/$appearance.log)"
  xcrun xcresulttool export attachments --path "$result" --output-path "$work/$appearance-att" >/dev/null
  node "$here/exportShots.mjs" "$work/$appearance-att" "$assets" "$device"
done
[ "$device" = "iphone" ] && xcrun simctl status_bar "$udid" clear
echo "Logs and results: $work"
