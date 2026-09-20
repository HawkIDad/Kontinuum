---
layout: layouts/concept.njk
title: "Blocks and anchors"
description: "Every note is made of blocks, and every block has a stable, human-readable anchor."
category: concepts
order: 2
appliesTo: ["1.0"]
platforms: ["iPhone","iPad","Mac"]
personas: ["Power User"]
featureSlug: blocks-and-anchors
lastReviewed: "2026-09-19"
type: concept
permalink: /en/help/concepts/blocks-and-anchors/
---

## What is a block?

A block is a paragraph, list item or heading inside a note. NoteBytez tracks each block separately.

## What is an anchor?

Each block gets a stable identifier and a short, readable anchor. You use the anchor to refer to the block from anywhere: `((anchor))` refers to it, and `!((anchor))` embeds it.

## Why does this matter?

Because the anchor stays with the block, references keep working when you edit other parts of the note, and an embedded block always shows the current text of its source.

## Related

- [Understand block anchors](/en/help/documents-and-blocks/block-anchors/)
- [Refer to a single block](/en/help/linking/block-references/)
- [Embed a block from another note](/en/help/linking/transclusion/)
