#!/bin/bash
# verify-rename.sh — enforces the Kontinuum → NoteBytez rename (see Kontinuum/Docs/Plans/NoteBytez.md).
#
# Fails (exit 1) if a user-visible "Kontinuum" reappears in:
#   (a) Swift string literals under Kontinuum/
#   (b) non-z_ Markdown body text under Kontinuum/
#       (NoteBytez.md and ARCHITECTURE.md's "Legacy Identifiers" section document both names — excepted)
#   (c) INFOPLIST_KEY_CFBundle{Display,}Name build settings
# Deliberate retentions (build/account identity — see ARCHITECTURE.md "Legacy Identifiers") are
# allow-listed below and never counted.
set -u
cd "$(dirname "$0")/.." || exit 2
fail=0

# Retained identifiers / paths — a line matching any of these is not a violation.
ALLOW='KontinuumTests|KontinuumUITests|KontinuumApp|KontinuumCIGate|KontinuumSecurity|Kontinuum/|Kontinuum\.xcodeproj|Kontinuum\.xcscheme|Kontinuum\.app|Kontinuum\.entitlements|Kontinuum-macOS\.entitlements|com\.g9Consulting\.Kontinuum|iCloud\.com\.g9Consulting\.Kontinuum|kontinuum-private-changes|kontinuum-shared-changes|import Kontinuum|-scheme Kontinuum|-project Kontinuum|-target Kontinuum'

echo "== (a) Swift string literals =="
while IFS= read -r hit; do
  echo "$hit" | grep -Eq "$ALLOW" && continue
  echo "  $hit"; fail=1
done < <(grep -rn '"[^"]*Kontinuum[^"]*"' --include='*.swift' Kontinuum/ 2>/dev/null | grep -v '^[0-9]*:[[:space:]]*//')

echo "== (b) Markdown body text =="
while IFS= read -r f; do
  case "$f" in */z_*|*/Docs/Plans/NoteBytez.md) continue;; esac
  # For ARCHITECTURE.md, drop the "## Legacy Identifiers" section (it names the retained identifiers).
  body=$(awk 'BEGIN{skip=0} /^## Legacy Identifiers/{skip=1;next} /^## /{skip=0} skip==0{print NR": "$0}' "$f")
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    echo "$hit" | grep -q 'Kontinuum' || continue
    echo "$hit" | grep -Eq "$ALLOW" && continue
    echo "  $f: $hit"; fail=1
  done <<< "$body"
done < <(find Kontinuum -name '*.md')

echo "== (c) Info.plist display-name keys =="
if grep -Eq 'INFOPLIST_KEY_CFBundle(Display)?Name = Kontinuum' Kontinuum.xcodeproj/project.pbxproj; then
  echo "  project.pbxproj still sets a Kontinuum display name"; fail=1
fi

if [ "$fail" -eq 0 ]; then echo "PASS — no user-visible Kontinuum references"; else echo "FAIL"; fi
exit $fail
