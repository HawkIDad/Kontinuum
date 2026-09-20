// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Built-site checks (W5): footer legal/support links on every page; App Store CTA on marketing pages.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const siteDir = new URL("../_site/", import.meta.url).pathname;
const footerLinks = ["/privacy/", "/terms/", "/support/"];
const ctaPages = ["index.html", "features/index.html", "pricing/index.html"];

export function missingFooterLinks(html) {
  const footer = /<footer[\s\S]*?<\/footer>/.exec(html)?.[0] ?? "";
  return footerLinks.filter((link) => !footer.includes(`href="${link}"`));
}

export function hasAppStoreCta(html, appStoreUrl) {
  return html.includes(`href="${appStoreUrl}"`);
}

function pages(directory = siteDir) {
  return readdirSync(directory).flatMap((name) => {
    const path = join(directory, name);
    if (name === "pagefind") return [];
    if (statSync(path).isDirectory()) return pages(path);
    return name === "index.html" ? [path] : [];
  });
}

function main() {
  const { appStoreUrl } = JSON.parse(readFileSync(new URL("../_data/site.json", import.meta.url), "utf8"));
  const errors = [];
  for (const path of pages()) {
    const html = readFileSync(path, "utf8");
    const relative = path.slice(siteDir.length);
    missingFooterLinks(html).forEach((link) => errors.push(`${relative}: footer missing ${link}`));
    if (ctaPages.includes(relative) && !hasAppStoreCta(html, appStoreUrl)) errors.push(`${relative}: no App Store CTA`);
  }
  errors.forEach((error) => console.error(`✖ ${error}`));
  if (errors.length > 0) process.exit(1);
  console.log("✔ footer links and App Store CTA present");
}

if (process.argv[1] === new URL(import.meta.url).pathname) main();
