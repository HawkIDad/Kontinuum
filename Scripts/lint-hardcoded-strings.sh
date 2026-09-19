#!/bin/bash
# lint-hardcoded-strings.sh — Phase 0.8 (R2) of
# NoteBytez/Docs/Plans/NoteBytez20260823v2- HOLD -MultiLanguage.md.
#
# SwiftUI auto-extracts a `Text("literal")`-style call into the String Catalog for free — this
# check exists for the *exceptions* R2 describes: call sites whose argument is a plain `String`
# rather than a `LocalizedStringKey`, so nothing auto-extracts even though the value the user
# sees may still be (partly) hardcoded English — `.navigationTitle(someEnum.rawValue)`, a
# ternary of two string literals passed to `.accessibilityLabel`, or an explicit
# `Text(verbatim:)` opt-out.
#
# Heuristic, regex-based (this repo has no SwiftSyntax tooling) — a `.navigationTitle(EXPR)` or
# `.accessibilityLabel(EXPR)` whose `EXPR` does not start with `"` (a plain string literal,
# which SwiftUI happily infers as `LocalizedStringKey`) is flagged. This deliberately does NOT
# distinguish "shows a user's own document/notebook title" (fine — G2: user content is never
# re-translated) from "shows a hardcoded English fallback/enum label" (a real gap) — that
# judgment call is Phase 2.1's, made once per finding; this script's only job is to make sure a
# finding is never silently missed or silently reintroduced after being fixed.
#
# Usage:
#   Scripts/lint-hardcoded-strings.sh                 # fail if any NEW offender exists
#   Scripts/lint-hardcoded-strings.sh --update-baseline  # accept the current findings as-is
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

baseline_file="Scripts/hardcoded-strings-baseline.txt"

find_offenders() {
  # --untracked: a brand-new file in a PR hasn't necessarily been `git add`ed yet when this
  # runs locally; without this flag `git grep` only sees committed/staged content.
  git grep --untracked -nE '\.(navigationTitle|accessibilityLabel)\([^")]' -- 'NoteBytez/*.swift' ':!NoteBytez*Tests*' 2>/dev/null || true
  git grep --untracked -n 'Text(verbatim:' -- 'NoteBytez/*.swift' ':!NoteBytez*Tests*' 2>/dev/null || true
}

current="$(find_offenders | sort)"

if [ "${1:-}" = "--update-baseline" ]; then
  echo "$current" > "$baseline_file"
  echo "Baseline updated: $(echo "$current" | grep -c . || true) offender(s) recorded in $baseline_file."
  exit 0
fi

if [ ! -f "$baseline_file" ]; then
  echo "No baseline at $baseline_file — run with --update-baseline first." >&2
  exit 1
fi

baseline="$(cat "$baseline_file")"
new_offenders="$(comm -13 <(echo "$baseline" | sort) <(echo "$current"))"

if [ -n "$new_offenders" ]; then
  echo "FAIL — new hardcoded-string offender(s) not in the baseline:"
  echo "$new_offenders"
  echo
  echo "Either wrap the value in a LocalizedStringKey-compatible literal, or — if this is a"
  echo "deliberate, reviewed exception (e.g. it displays a user's own document title, per G2) —"
  echo "re-run with --update-baseline to accept it."
  exit 1
fi

removed="$(comm -23 <(echo "$baseline" | sort) <(echo "$current"))"
if [ -n "$removed" ]; then
  echo "Note: $(echo "$removed" | grep -c .) previously-baselined offender(s) no longer present — run --update-baseline to shrink the baseline."
fi

echo "OK — no new hardcoded-string offenders."
