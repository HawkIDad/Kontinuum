---
layout: layouts/marketing.njk
title: Support and contact
description: Get help with NoteBytez — find answers in the Help section, or contact support with the details that let us fix things quickly.
permalink: /support/
faq:
  - q: Where do I find how-to guides?
    a: The Help section has a step-by-step guide for every feature, plus concepts and reference pages.
  - q: What should I include when I contact support?
    a: Your device and NoteBytez version, what you expected to happen, what happened instead, and any message you saw. Please do not send your notes unless we ask.
  - q: Does support have access to my notes?
    a: No. NoteBytez has no server that holds your notes, so we cannot see them.
---
## Find the answer yourself

The [Help section](/en/help/) has a step-by-step guide for every feature. Common starting points:

- {% helpLink "sync-and-conflicts", "sync-status", "Sync status and what it means" %}
- {% helpLink "sync-and-conflicts", "resolve-conflicts", "Resolving a conflict" %}
- {% helpLink "backup-and-restore", "restore-snapshot", "Restoring from a backup" %}
- {% helpLink "subscription-and-account", "restore-purchases", "Restoring a purchase" %}
- {% helpLink "markdown-import-export", "export-library", "Exporting your notes" %}

## Contact us

{% if site.supportEmail | isSet %}
Email <a href="mailto:{{ site.supportEmail }}">{{ site.supportEmail }}</a>.
{% else %}
Contact details are provided in the {{ site.name }} listing on the App Store.
{% endif %}

Include your device and {{ site.name }} version, what you expected, what happened, and any message you saw. We will see what you send us, so leave out anything private. We cannot see your notes.
