---
layout: layouts/howto.njk
title: "Choose how conflicts are resolved"
description: "Decide what happens when two devices edit the same note."
category: sync-and-conflicts
order: 4
appliesTo: ["1.0"]
platforms: ["iPhone","iPad","Mac"]
personas: ["Switcher","Power User"]
featureSlug: choose-conflict-strategy
lastReviewed: "2026-09-19"
type: howto
permalink: /en/help/sync-and-conflicts/choose-conflict-strategy/
---

## Purpose

Decide what happens when two devices edit the same note.

## Prerequisites

None.

## Steps

1. Open **Settings** and choose **Sync & Conflicts**.
2. Under **Conflict resolution strategy**, choose one: **Keep All Versions** (you resolve every conflict), **Last-Write-Wins + Banner** (the newest edit wins and a banner lets you revert) or **Markdown Diff-Merge** (text is auto-merged and you review the diff).

{% screenshot "sync-and-conflicts/choose-conflict-strategy-iphone-light.png", "The Sync and Conflicts settings with three conflict strategies to choose from.", "Choosing a conflict strategy." %}

## Expected result

Future conflicts follow the strategy you chose.

## Related

- [The three conflict strategies compared](/en/help/concepts/conflict-strategies-compared/)
- [Resolve a conflict](/en/help/sync-and-conflicts/resolve-conflicts/)
