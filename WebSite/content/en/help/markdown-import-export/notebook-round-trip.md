---
layout: layouts/howto.njk
title: "How notebooks survive export and import"
description: "Understand how notebook membership is written to Markdown and read back."
category: markdown-import-export
order: 4
appliesTo: ["1.0"]
platforms: ["iPhone","iPad","Mac"]
personas: ["Switcher","Power User"]
featureSlug: notebook-round-trip
lastReviewed: "2026-09-19"
type: howto
permalink: /en/help/markdown-import-export/notebook-round-trip/
---

## Purpose

Understand how notebook membership is written to Markdown and read back.

## Prerequisites

A library with notebooks.

## Steps

1. Export your library.
2. Open an exported file: a `notebooks:` list in its front matter names each notebook, and a `#notebook/<name>` tag is added to the end of the body.
3. Import the folder into NoteBytez. The `notebooks:` list restores membership.

{% admonition "note" %}The `#notebook/…` tag is only for other tools such as Obsidian and Logseq; NoteBytez does not read it back.{% endadmonition %}

## Expected result

Notebook membership round-trips through Markdown.

## Related

- [Import a folder of Markdown files](/en/help/markdown-import-export/import-markdown/)
- [Export your whole library](/en/help/markdown-import-export/export-library/)
