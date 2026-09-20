// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Built-site internal link check + orphan check (Wiki SF1: zero orphan pages, no broken links).
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const siteDir = new URL("../_site/", import.meta.url).pathname;

export function extractInternalLinks(html) {
  return [...html.matchAll(/<a [^>]*href="([^"]+)"/g)]
    .map((match) => match[1].split("#")[0])
    .filter((href) => href.startsWith("/") && !href.startsWith("//"));
}

/** pages: Map<url, links[]> */
export function findBrokenLinks(pages) {
  return [...pages].flatMap(([url, links]) => links.filter((link) => !pages.has(link)).map((link) => [url, link]));
}

export function findOrphans(pages, urlsToCheck) {
  const linked = new Set([...pages].flatMap(([url, links]) => links.filter((link) => link !== url)));
  return urlsToCheck.filter((url) => !linked.has(url));
}

function readPages(directory = siteDir, prefix = "/") {
  return readdirSync(directory).flatMap((name) => {
    const path = join(directory, name);
    if (name === "pagefind") return [];
    if (statSync(path).isDirectory()) return readPages(path, `${prefix}${name}/`);
    return name === "index.html" ? [[prefix, extractInternalLinks(readFileSync(path, "utf8"))]] : [];
  });
}

function main() {
  const pages = new Map(readPages());
  const broken = findBrokenLinks(pages).filter(([, link]) => !/\.\w+$/.test(link));
  const orphans = findOrphans(pages, [...pages.keys()].filter((url) => url !== "/"));
  broken.forEach(([page, link]) => console.error(`✖ broken link on ${page}: ${link}`));
  orphans.forEach((url) => console.error(`✖ orphan page: ${url}`));
  if (broken.length + orphans.length > 0) process.exit(1);
  console.log(`✔ ${pages.size} pages: no broken internal links, no orphans`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
