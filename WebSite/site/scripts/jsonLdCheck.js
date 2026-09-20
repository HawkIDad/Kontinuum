// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Structural JSON-LD validation (required properties per type). Not a substitute for Google's Rich Results Test.
const requiredByType = {
  BreadcrumbList: ["itemListElement"],
  WebSite: ["name", "url", "potentialAction"],
  HowTo: ["name", "step"],
  TechArticle: ["headline", "description"],
  FAQPage: ["mainEntity"],
};

export function extractJsonLd(html) {
  return [...html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)].map((match) => match[1]);
}

export function validateJsonLd(html) {
  const errors = [];
  for (const raw of extractJsonLd(html)) {
    let data;
    try { data = JSON.parse(raw); } catch { errors.push("invalid JSON in JSON-LD block"); continue; }
    if (data["@context"] !== "https://schema.org") errors.push(`${data["@type"]}: bad @context`);
    const required = requiredByType[data["@type"]];
    if (!required) { errors.push(`unknown @type ${data["@type"]}`); continue; }
    for (const key of required) if (!data[key] || data[key].length === 0) errors.push(`${data["@type"]}: missing ${key}`);
  }
  return errors;
}
