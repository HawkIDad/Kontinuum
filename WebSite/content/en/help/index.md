---
layout: layouts/marketing.njk
title: Help
description: Step-by-step guides for every NoteBytez feature, plus concepts, reference pages and four guided journeys.
permalink: /en/help/
---
Step-by-step guides for every NoteBytez feature. Use the search box above, start with a journey, or browse by topic.

## Start with a journey

{% for item in collections.helpPages | pagesIn("journeys") %}
- [{{ item.data.title }}]({{ item.url }}) — {{ item.data.description }}
{% endfor %}

## Browse by topic

{% for hub in helpHubs %}{% if hub.slug != "journeys" %}
- [{{ hub.title }}](/en/help/{{ hub.slug }}/)
{% endif %}{% endfor %}
