// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Built-site SEO / AI-retrieval checks (Wiki SF4): per-page tags, sitemap coverage, llms.txt links,
// robots.txt, static readability without JavaScript, JSON-LD structure.
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { validateJsonLd } from "./jsonLdCheck.js";

const siteDir = new URL("../_site/", import.meta.url).pathname;

export function checkPageSeo(html, url) {
  const errors = [];
  const fail = (message) => errors.push(`${url}: ${message}`);
  if (!/<html lang="[a-z-]+"/.test(html)) fail("missing lang on <html>");
  if (!/<link rel="canonical" href="[^"]+"/.test(html)) fail("missing canonical link");
  const description = /<meta name="description" content="([^"]*)"/.exec(html)?.[1] ?? "";
  if (description.length < 50 || description.length > 300) fail(`meta description length ${description.length} (want 50–300)`);
  for (const tag of ['property="og:title"', 'property="og:description"', 'property="og:url"', 'name="twitter:card"']) {
    if (!html.includes(tag)) fail(`missing ${tag}`);
  }
  if ((html.match(/<h1[ >]/g) ?? []).length !== 1) fail("needs exactly one h1");
  const main = /<main[\s\S]*?<\/main>/.exec(html)?.[0] ?? "";
  const text = main.replace(/<script[\s\S]*?<\/script>/g, "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
  if (text.split(" ").length < 20) fail("no readable content without JavaScript");
  return errors;
}

export const sitemapUrls = (xml) => [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);
export const llmsLinks = (text) => [...text.matchAll(/\]\((https?:[^)\s]+)\)/g)].map((match) => match[1]);
export const robotsHasSitemap = (text) => /^Sitemap:\s*\S+/m.test(text);

function pages(directory = siteDir, prefix = "/") {
  return readdirSync(directory).flatMap((name) => {
    const path = join(directory, name);
    if (name === "pagefind") return [];
    if (statSync(path).isDirectory()) return pages(path, `${prefix}${name}/`);
    return name === "index.html" ? [[prefix, path]] : [];
  });
}

function main() {
  const { baseUrl } = JSON.parse(readFileSync(new URL("../_data/site.json", import.meta.url), "utf8"));
  const errors = [];
  const sitemap = new Set(sitemapUrls(readFileSync(join(siteDir, "sitemap.xml"), "utf8")));
  for (const [url, path] of pages()) {
    const html = readFileSync(path, "utf8");
    errors.push(...checkPageSeo(html, url), ...validateJsonLd(html).map((error) => `${url}: ${error}`));
    if (!sitemap.has(`${baseUrl}${url}`)) errors.push(`${url}: not in sitemap.xml`);
  }
  if (!robotsHasSitemap(readFileSync(join(siteDir, "robots.txt"), "utf8"))) errors.push("robots.txt: no Sitemap line");
  const known = new Set(pages().map(([url]) => `${baseUrl}${url}`));
  for (const file of ["llms.txt", ...readdirSync(join(siteDir, "en/help")).filter((d) => existsSync(join(siteDir, "en/help", d, "llms.txt"))).map((d) => `en/help/${d}/llms.txt`)]) {
    for (const link of llmsLinks(readFileSync(join(siteDir, file), "utf8"))) {
      if (!known.has(link)) errors.push(`${file}: link to unknown page ${link}`);
    }
  }
  errors.forEach((error) => console.error(`✖ ${error}`));
  if (errors.length > 0) process.exit(1);
  console.log(`✔ SEO checks pass on ${sitemap.size} pages (tags, sitemap, robots, llms.txt, static content, JSON-LD)`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
