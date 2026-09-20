// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Nunjucks filters: breadcrumbs, pager siblings, HowTo step extraction, JSON-LD serialising.

export function buildBreadcrumbs(url, title, featureMap) {
  const segments = url.split("/").filter(Boolean);
  const crumbs = [{ name: "Home", url: "/" }];
  if (segments.length === 0) return crumbs;
  if (segments[0] !== "en" || segments[1] !== "help") {
    return [...crumbs, { name: title, url }];
  }
  crumbs.push({ name: "Help", url: "/en/help/" });
  if (segments.length === 2) return crumbs;
  const categorySlug = segments[2];
  const category = featureMap.categories.find((entry) => entry.slug === categorySlug);
  crumbs.push({ name: category?.title ?? "Journeys", url: `/en/help/${categorySlug}/` });
  if (segments.length > 3) crumbs.push({ name: title, url });
  return crumbs;
}

export function siblingsOf(collection, currentUrl) {
  const current = collection.find((item) => item.url === currentUrl);
  if (!current) return {};
  const peers = collection
    .filter((item) => item.data.category === current.data.category && item.data.type !== "journey")
    .sort((first, second) => first.data.order - second.data.order);
  const index = peers.indexOf(current);
  return { previous: peers[index - 1], next: peers[index + 1] };
}

export function extractSteps(html) {
  const list = /<ol[^>]*>([\s\S]*?)<\/ol>/.exec(html ?? "");
  if (!list) return [];
  const items = [...list[1].matchAll(/<li[^>]*>([\s\S]*?)<\/li>/g)];
  return items.map((match) => match[1].replace(/<figure[\s\S]*?<\/figure>/g, "").replace(/<[^>]+>/g, "").trim());
}

/** Q&A pairs from "<h2>question?</h2><p>answer</p>" — the shape concept pages use, for FAQPage JSON-LD. */
export function faqFromHeadings(html) {
  const strip = (text) => text.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
  return [...(html ?? "").matchAll(/<h2[^>]*>([^<]*\?)<\/h2>\s*<p>([\s\S]*?)<\/p>/g)].map((match) => ({ q: strip(match[1]), a: strip(match[2]) }));
}

export function addFilters(eleventyConfig, featureMap) {
  eleventyConfig.addFilter("breadcrumbs", (url, title) => buildBreadcrumbs(url, title, featureMap));
  eleventyConfig.addFilter("siblings", siblingsOf);
  eleventyConfig.addFilter("howToSteps", extractSteps);
  eleventyConfig.addFilter("faqFromHeadings", faqFromHeadings);
  eleventyConfig.addFilter("isCurrent", (itemUrl, pageUrl) => (itemUrl === "/" ? pageUrl === "/" : pageUrl.startsWith(itemUrl)));
  eleventyConfig.addFilter("pagesIn", (collection, category) =>
    collection.filter((item) => item.data.category === category).sort((first, second) => first.data.order - second.data.order));
  eleventyConfig.addFilter("categoryTitle", (slug) => featureMap.categories.find((entry) => entry.slug === slug)?.title ?? "Journeys");
  eleventyConfig.addFilter("isSet", (value) => Boolean(value) && !String(value).startsWith("TODO"));
  eleventyConfig.addFilter("jsonLd", (value) => JSON.stringify(value).replace(/</g, "\\u003c"));
}
