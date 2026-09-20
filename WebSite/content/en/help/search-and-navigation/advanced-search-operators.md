---
layout: layouts/howto.njk
title: "Combine search terms with operators"
description: "Use AND, OR, NOT, phrases, regular expressions and tags in one search."
category: search-and-navigation
order: 3
appliesTo: ["1.0"]
platforms: ["iPhone","iPad","Mac"]
personas: ["Power User"]
featureSlug: advanced-search-operators
lastReviewed: "2026-09-19"
type: howto
permalink: /en/help/search-and-navigation/advanced-search-operators/
---

## Purpose

Use AND, OR, NOT, phrases, regular expressions and tags in one search.

## Prerequisites

The Search screen is open.

## Steps

1. Turn on the advanced search button next to the search box. Its label changes to **Advanced Search: On**.
2. Type an expression such as `#character AND #act2 NOT #resolved`. You can use `AND`, `OR`, `NOT`, `"an exact phrase"`, `/regex/` and `#tag`.
3. Choose a result to open it.

{% screenshot "search-and-navigation/advanced-search-iphone-light.png", "The Search screen with advanced search switched on and a hint showing the operators.", "Advanced search." %}

## Expected result

Results match the whole expression. A `#tag` term always matches the note's tags; other terms use the scope you chose.

## Related

- [Search by content, tag or path](/en/help/search-and-navigation/scoped-search-filters/)
- [Save a search or filter as a view](/en/help/search-and-navigation/saved-views/)
