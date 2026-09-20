#!/bin/bash
# capture.sh — regenerates website screenshots for one category from the committed seed library.
# WebSite20260919v1-WebSite.md Phase W4. Requires Xcode and node; the Mac capture also needs
# Screen Recording permission for the app running this script (System Settings > Privacy & Security).
#
# Usage: capture.sh <category> [iphone|mac]      e.g. capture.sh notebooks     (default: both)
# Output: WebSite/content/en/_assets/<category>/<name>-<device>-<appearance>[@2x].png
#         iphone: 400 / 800 px wide; mac: 800 / 1600 px wide. Convention: WebSite/docs/styleGuide.md.
# iPhone uses a dedicated simulator created on first run (portrait, clean state). The Mac app is
# launched with settings in environment variables: on macOS a `-Key value` argument pair makes
# AppKit treat the value as a file to open, which suppresses the main window.
set -euo pipefail

category="${1:?usage: capture.sh <category> [iphone|mac]}"
devices="${2:-iphone mac}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
assets="$repo/WebSite/content/en/_assets/$category"
build="$here/.build"
bundle_id="com.kwicksync.NoteBytez"
sim_name="NoteBytez Screenshots (iPhone 17 Pro)"

shots="$(node -e '
  const m = require(process.argv[1]);
  m.shots.filter(s => s.category === process.argv[2]).forEach(s => console.log(s.name + "|" + s.destination));
' "$here/manifest.json" "$category")"
[ -n "$shots" ] || { echo "No shots for category '$category' in manifest.json" >&2; exit 1; }
mkdir -p "$assets"

# resize <native.png> <basePath> <1x width>  ->  <basePath>.png and <basePath>@2x.png
resize() {
  sips --resampleWidth "$(($3 * 2))" "$1" --out "$2@2x.png" >/dev/null
  sips --resampleWidth "$3" "$1" --out "$2.png" >/dev/null
  rm "$1"
}

capture_iphone() {
  local udid runtime
  udid="$(xcrun simctl list devices -j | node -e 'const d=JSON.parse(require("fs").readFileSync(0));console.log(Object.values(d.devices).flat().find(v=>v.name===process.argv[1]&&v.isAvailable)?.udid??"")' "$sim_name")"
  if [ -z "$udid" ]; then
    runtime="$(xcrun simctl list runtimes -j | node -e 'const r=JSON.parse(require("fs").readFileSync(0)).runtimes.filter(x=>x.isAvailable&&x.platform==="iOS");console.log(r[r.length-1].identifier)')"
    udid="$(xcrun simctl create "$sim_name" "iPhone 17 Pro" "$runtime")"
  fi
  xcrun simctl bootstatus "$udid" -b >/dev/null
  echo "▶ Building iPhone app…"
  xcodebuild build -quiet -project "$repo/NoteBytez.xcodeproj" -scheme NoteBytez \
    -destination "id=$udid" -derivedDataPath "$build" >/dev/null
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
    --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --operatorName ""
  xcrun simctl install "$udid" "$build/Build/Products/Debug-iphonesimulator/NoteBytez.app"

  while IFS='|' read -r name destination; do
    for appearance in light dark; do
      xcrun simctl ui "$udid" appearance "$appearance"
      sleep 3
      xcrun simctl terminate "$udid" "$bundle_id" >/dev/null 2>&1 || true
      xcrun simctl launch "$udid" "$bundle_id" -SkipLanguagePrompt \
        -SeedScreenshotLibrary "$here/seedLibrary" -ScreenshotDestination "$destination" \
        -AppleLanguages "(en)" -AppleLocale en_US >/dev/null
      sleep 6
      xcrun simctl io "$udid" screenshot --type=png "$assets/$name.native.png" >/dev/null 2>&1
      resize "$assets/$name.native.png" "$assets/$name-iphone-$appearance" 400
      echo "✔ $name iphone ($appearance)"
    done
  done <<< "$shots"
  xcrun simctl terminate "$udid" "$bundle_id" >/dev/null 2>&1 || true
  xcrun simctl status_bar "$udid" clear
  xcrun simctl ui "$udid" appearance light
}

# Prints the CGWindowID of NoteBytez's main window (the on-screen NoteBytez window taller than 300 pt).
mac_window_id() {
  osascript -l JavaScript -e '
    ObjC.import("CoreGraphics");
    var windows = ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo(0, 0)));
    var main = windows.filter(w => w.kCGWindowOwnerName == "NoteBytez" && w.kCGWindowIsOnscreen && w.kCGWindowBounds.Height > 300)[0];
    main ? String(main.kCGWindowNumber) : ""'
}

# Hover state changes toolbar button rendering, so park the pointer in the screen corner.
park_mouse() {
  osascript -l JavaScript -e 'ObjC.import("CoreGraphics"); $.CGWarpMouseCursorPosition($.CGPointMake(1727, 1083));' >/dev/null
}

capture_mac() {
  echo "▶ Building Mac app…"
  xcodebuild build -quiet -project "$repo/NoteBytez.xcodeproj" -scheme NoteBytez \
    -destination 'platform=macOS' -derivedDataPath "$build" >/dev/null
  local app="$build/Build/Products/Debug/NoteBytez.app" windowId attempt
  # The Mac app is sandboxed and cannot read the repo (or be written into), so pass the seed notes inline.
  local notesJson
  notesJson="$(node -e 'const fs=require("fs"),p=require("path");const d=process.argv[1];console.log(JSON.stringify(Object.fromEntries(fs.readdirSync(d).filter(f=>f.endsWith(".md")).map(f=>[f,fs.readFileSync(p.join(d,f),"utf8")]))))' "$here/seedLibrary")"

  while IFS='|' read -r name destination; do
    for appearance in light dark; do
      pkill -x NoteBytez 2>/dev/null || true
      sleep 2
      open -n "$app" --env SeedScreenshotNotes="$notesJson" --env ScreenshotDestination="$destination" \
        --env ScreenshotAppearance="$appearance" --args -SkipLanguagePrompt
      windowId=""
      for attempt in 1 2 3 4 5 6 7 8 9 10; do
        sleep 2
        windowId="$(mac_window_id)"
        [ -n "$windowId" ] && break
      done
      [ -n "$windowId" ] || { echo "✖ no NoteBytez window (is the build launching?)" >&2; exit 1; }
      park_mouse
      sleep 6
      screencapture -x -o -l "$windowId" "$assets/$name.native.png"
      resize "$assets/$name.native.png" "$assets/$name-mac-$appearance" 800
      echo "✔ $name mac ($appearance)"
    done
  done <<< "$shots"
  pkill -x NoteBytez 2>/dev/null || true
}

for device in $devices; do
  case "$device" in
    iphone) capture_iphone ;;
    mac) capture_mac ;;
    *) echo "Unknown device '$device'" >&2; exit 1 ;;
  esac
done
