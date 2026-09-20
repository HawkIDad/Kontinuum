<!-- prospectWalkthrough.md -->
<!-- Phase W5 verify: a prospect can answer what / who / cost / how to get it within 2 clicks (Success Factor 2). Written walkthrough; no analytics. -->

# Prospect walkthrough

Start: the home page (`/`). Clicks are counted from there.

| Question | Where the answer is | Clicks |
|---|---|---|
| **What is it?** | Home hero and the "What you can do" grid (answered on the landing page). Full tour: **Features** | 0 / 1 |
| **Who is it for?** | Home › "Who it is for" section (Apple Notes / Obsidian / power users / sharing). Also the FAQ | 0 |
| **What does it cost?** | Nav › **Pricing** (subscription, monthly or annual, free trial, what happens on lapse) | 1 |
| **How do I get it?** | The **Get NoteBytez on the App Store** button in the hero of Home, Features and Pricing | 0 |
| **What does sync do?** (Wiki SF2 prospect task) | Home › feature card "Sync without losing an edit" › Help *Sync status* (or Features › Sync) | 1–2 |
| **Is my data safe / who sees it?** | Footer › **Privacy** (states no analytics or cookies; local-first + CloudKit) | 1 |

Every page footer links Privacy, Terms and Support (`npm run check:pages` verifies this on every built page). Home, Features and Pricing each carry the App Store CTA (also verified).

**Open until the values are known:** the App Store URL, the price and the trial length in `site/_data/site.json`. Pricing renders without numbers while they are `TODO-…`, and the App Store button points at a placeholder URL.
