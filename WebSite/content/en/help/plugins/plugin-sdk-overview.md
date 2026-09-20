---
layout: layouts/howto.njk
title: "What plugins can and cannot do"
description: "A reader-level overview of the plugin sandbox."
category: plugins
order: 3
appliesTo: ["1.0"]
platforms: ["iPhone","iPad","Mac"]
personas: ["Power User"]
featureSlug: plugin-sdk-overview
lastReviewed: "2026-09-19"
type: howto
permalink: /en/help/plugins/plugin-sdk-overview/
---

## Purpose

A reader-level overview of the plugin sandbox.

## Prerequisites

None.

## Steps

1. A plugin runs in a sandbox.
2. It can read your library, write to the current note and add commands, each only if you granted that permission.
3. It cannot do anything outside those permissions.

## Expected result

You know the limits of a plugin before you install one.

## Related

- [Understand plugin permissions](/en/help/plugins/plugin-permissions/)
