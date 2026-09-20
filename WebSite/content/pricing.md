---
layout: layouts/marketing.njk
title: Pricing
description: NoteBytez is a subscription billed monthly or annually through the App Store, with a free trial. Family Sharing is supported and your notes can always be exported.
permalink: /pricing/
faq:
  - q: Is there a free trial?
    a: Yes. New subscribers start with a free trial through the App Store, and can cancel at any time before it ends.
  - q: What happens if my subscription lapses?
    a: You get a short grace period with a banner. After that the app stops editing, nothing is deleted, and you can still export all of your notes. Resubscribing restores full access with no data loss.
  - q: Can I use NoteBytez offline?
    a: Yes. Once your subscription has been verified you can keep working offline for up to a week, then NoteBytez asks you to reconnect.
  - q: Does one subscription cover all my devices?
    a: Yes. A subscription covers every device signed in to your Apple Account, and your family through Family Sharing.
---
NoteBytez is a subscription. You subscribe through the App Store, so billing, renewal and cancellation are all managed in your Apple Account settings.

## Plans

- **Monthly** — billed every month.
- **Annual** — billed once a year.
{% if site.price | isSet %}
Price: {{ site.price }}.
{% endif %}
{% if site.trialLength | isSet %}
Every new subscription starts with a {{ site.trialLength }} free trial.
{% else %}
Every new subscription starts with a free trial.
{% endif %}

## What you get

Full access to NoteBytez on iPhone, iPad and Mac: every feature described on the [Features](/features/) page, sync through iCloud, backups and sharing.

## If a subscription ends

Your notes are never held hostage.

1. **Grace period.** When a subscription lapses, a banner shows how much time is left.
2. **Read-only access to your notes.** After the grace period the app stops editing, but nothing is deleted and you can export every note as Markdown.
3. **Resubscribe any time.** Full functionality returns with no data loss.

See {% helpLink "subscription-and-account", "lapse-grace-banner", "what the grace banner means" %} and {% helpLink "subscription-and-account", "read-only-export", "how to export after a lapse" %}.
