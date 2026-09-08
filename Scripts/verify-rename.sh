#!/bin/bash
# verify-rename.sh — enforces the completed Kontinuum -> NoteBytez rename
# (see NoteBytez/Docs/Plans/NoteBytez20260908v1-ProjectRename.md).
#
# Fails (exit 1) if a case-insensitive "kontinuum" appears in ANY git-tracked
# text file, with exactly one allowed exception:
#
#   iCloud.com.g9Consulting.Kontinuum   — the CloudKit container. Containers
#   cannot be renamed; with pre-launch disposable data there is no reason to
#   make a new one. This is the sole retained legacy identifier.
#
# Binary files are skipped (git grep -I). This script excludes itself.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

ALLOWED='iCloud\.com\.g9Consulting\.Kontinuum'

# Every case-insensitive "kontinuum" hit in tracked text, minus this script,
# minus lines that are only the allowed container literal.
hits="$(git grep -nI -i -e kontinuum -- ':!Scripts/verify-rename.sh' \
        | grep -viE "$ALLOWED" || true)"

if [ -n "$hits" ]; then
  echo "FAIL — disallowed 'Kontinuum' reference(s) found:"
  echo "$hits"
  echo
  echo "The only permitted occurrence is the CloudKit container literal"
  echo "  iCloud.com.g9Consulting.Kontinuum"
  exit 1
fi

# Sanity: the container literal must still be present (guards against an
# over-eager sweep that also renamed the container).
if ! git grep -qI "$ALLOWED"; then
  echo "FAIL — CloudKit container literal iCloud.com.g9Consulting.Kontinuum not found;"
  echo "       it must be retained in the entitlement files and sync/dal constants."
  exit 1
fi

echo "PASS — no Kontinuum references outside the retained CloudKit container."
