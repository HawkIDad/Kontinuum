#!/bin/bash
# run-pseudolocalized.sh — Phase 0.9 / R1 of
# NoteBytez/Docs/Plans/NoteBytez20260823v2- HOLD -MultiLanguage.md.
#
# Builds and launches NoteBytez in a booted iOS Simulator under one of Apple's built-in
# pseudolocalization modes, verified working against a real build (see the Phase 0/2 execution
# notes in that plan doc — real screenshots, not a guess): the flags below are the same ones
# Xcode's own scheme-editor "App Language" pseudolanguage picker uses, launched directly via
# `simctl` so this is scriptable without opening Xcode.
#
# Usage:
#   Scripts/run-pseudolocalized.sh double-length   # every string doubled + uppercased + bracketed
#   Scripts/run-pseudolocalized.sh rtl              # right-to-left layout mirroring
#   Scripts/run-pseudolocalized.sh accented         # accented characters, catches non-localized text
#
# Run this against every screen touched by a PR before real translations exist (R1) — it catches
# hardcoded strings, truncation, and layout breaks that a plain English run never surfaces.
set -euo pipefail

mode="${1:-}"
device="${2:-booted}"
bundle_id="com.kwicksync.NoteBytez"

usage() {
  echo "Usage: $0 <double-length|rtl|accented> [device-udid-or-name]" >&2
  exit 1
}

[ -n "$mode" ] || usage

case "$mode" in
  double-length)
    # Doubles + uppercases + brackets every localized string — the classic "does this truncate
    # in a longer language" check (German, Finnish, ... routinely run 30-50% longer than English).
    extra_args=(-NSDoubleLocalizedStrings YES)
    ;;
  rtl)
    # Mirrors layout direction system-wide, independent of any actual Arabic/Hebrew locale
    # existing yet — exercises Phase 9/11's `.leading`/`.trailing` audit before `ar` ships.
    extra_args=(-AppleTextDirection YES -NSForceRightToLeftWritingDirection YES)
    ;;
  accented)
    # Marks every string that resolved from the base language (never localized) distinctly from
    # one that went through the String Catalog — useful once Phase 2 starts populating keys, to
    # spot what's still falling back to en-US.
    extra_args=(-NSShowNonLocalizedStrings YES)
    ;;
  *)
    usage
    ;;
esac

resolved_device="$device"
if [ "$device" = "booted" ]; then
  resolved_device="$(xcrun simctl list devices booted -j | /usr/bin/python3 -c \
    'import json,sys; d=json.load(sys.stdin)["devices"]; print(next((v["udid"] for k in d for v in d[k] if v.get("state")=="Booted"), ""))')"
  if [ -z "$resolved_device" ]; then
    echo "No booted simulator found — pass a device UDID/name, or boot one first." >&2
    exit 1
  fi
fi

xcrun simctl terminate "$resolved_device" "$bundle_id" >/dev/null 2>&1 || true
echo "Launching $bundle_id on $resolved_device under '$mode' pseudolocalization..."
xcrun simctl launch "$resolved_device" "$bundle_id" "${extra_args[@]}"
