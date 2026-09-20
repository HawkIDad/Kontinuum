---
layout: layouts/concept.njk
title: "How NoteBytez syncs your notes"
description: "NoteBytez is local-first: your notes live on your device and sync through your own iCloud account."
category: concepts
order: 1
appliesTo: ["1.0"]
platforms: ["iPhone","iPad","Mac"]
personas: ["New Arrival","Switcher"]
featureSlug: sync-model
lastReviewed: "2026-09-19"
type: concept
permalink: /en/help/concepts/sync-model/
---

## How does NoteBytez store my notes?

Your notes are stored on your device first, so NoteBytez works without a connection. When you are online and signed in to iCloud, changes sync to your other devices through Apple CloudKit.

## Does NoteBytez have a server?

No. There is no NoteBytez server that holds a copy of your notes. Sync, sharing and subscription checks happen between your devices and Apple's own services.

## Is my data protected?

Apple CloudKit encrypts synced data in transit and at rest, and your device protects the local copy with the platform's own data protection.

## What if two devices disagree?

If the same note is edited on two devices, NoteBytez detects the conflict and resolves it using the strategy you chose. See the comparison of strategies below.

## What happens offline?

You can keep working. Changes sync when you reconnect, and the sync icon shows when you last synced.

## Related

- [Check sync status](/en/help/sync-and-conflicts/sync-status/)
- [The three conflict strategies compared](/en/help/concepts/conflict-strategies-compared/)
- [Your data is plain Markdown](/en/help/concepts/plain-markdown-data/)
