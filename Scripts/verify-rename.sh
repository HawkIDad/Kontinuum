#!/bin/bash
# verify-rename.sh — enforces the completed identifier rebase to
# NoteBytez / com.kwicksync (see NoteBytez/Docs/Plans/NoteBytez20260908v1-ProjectRename.md
# and NoteBytez/Docs/Plans/NoteBytez20260909v1-Bundle.md).
#
# Fails (exit 1) if a case-insensitive "kontinuum" OR "g9consulting" appears in
# any git-tracked text file. There is no allow-list: the CloudKit container was
# re-homed to iCloud.com.kwicksync.NoteBytez, so no legacy identifier is retained.
#
# Excluded, because they are historical narrative rather than shipping code or
# configuration, and legitimately name the retired identifiers to record the change:
#   - this script
#   - NoteBytez/ARCHITECTURE.md               ("Identifier History" section)
#   - NoteBytez/Docs/Plans/*.md               (dated plan documents)
#
# Binary files are skipped (git grep -I).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Every case-insensitive hit in tracked text, minus the historical-narrative files.
hits="$(git grep -nI -iE 'kontinuum|g9consulting' -- \
          ':!Scripts/verify-rename.sh' \
          ':!NoteBytez/ARCHITECTURE.md' \
          ':!NoteBytez/Docs/Plans/*.md' || true)"

if [ -n "$hits" ]; then
  echo "FAIL — retired identifier(s) found in shipping code / config / non-historical docs:"
  echo "$hits"
  echo
  echo "No legacy identifier is retained. Sweep to com.kwicksync / iCloud.com.kwicksync.NoteBytez."
  echo "If the occurrence is deliberate historical narrative, it belongs in a Docs/Plans/*.md"
  echo "plan document or ARCHITECTURE.md's Identifier History section, not here."
  exit 1
fi

# Sanity: the new container literal must be present (guards against an over-eager
# sweep that also renamed the container out of the entitlements / sync constants).
if ! git grep -qI "iCloud\.com\.kwicksync\.NoteBytez"; then
  echo "FAIL — CloudKit container literal iCloud.com.kwicksync.NoteBytez not found;"
  echo "       it must be present in both entitlement files and the sync/dal constants."
  exit 1
fi

echo "PASS — no retired identifiers outside historical narrative; new container literal present."
