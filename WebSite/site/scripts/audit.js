// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Per-page audit: axe-core (zero violations), Lighthouse (a11y/SEO/best-practices ≥ 95), JSON-LD structure.
// Usage: SAMPLES=1 npm run build && npm run audit   (needs CHROME_PATH or Google Chrome on macOS)
import { createServer } from "node:http";
import { readFileSync, existsSync, statSync, readdirSync } from "node:fs";
import { join, extname } from "node:path";
import puppeteer from "puppeteer-core";
import lighthouse from "lighthouse";
import { validateJsonLd } from "./jsonLdCheck.js";

const siteDir = new URL("../_site/", import.meta.url).pathname;
const chromePath = process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const threshold = 0.95;
const types = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".json": "application/json", ".wasm": "application/wasm" };

function pagePaths(directory = siteDir, prefix = "/") {
  return readdirSync(directory).flatMap((name) => {
    if (name === "pagefind") return [];
    const path = join(directory, name);
    if (statSync(path).isDirectory()) return pagePaths(path, `${prefix}${name}/`);
    return name === "index.html" ? [prefix] : [];
  });
}

function serve() {
  const server = createServer((request, response) => {
    const urlPath = decodeURIComponent(request.url.split("?")[0]);
    let file = join(siteDir, urlPath);
    if (existsSync(file) && statSync(file).isDirectory()) file = join(file, "index.html");
    if (!existsSync(file)) { response.writeHead(404).end(); return; }
    response.writeHead(200, { "content-type": types[extname(file)] ?? "application/octet-stream" }).end(readFileSync(file));
  });
  return new Promise((resolve) => server.listen(0, () => resolve(server)));
}

async function axeViolations(browser, url) {
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: "networkidle0" });
  await page.addScriptTag({ path: new URL("../node_modules/axe-core/axe.min.js", import.meta.url).pathname });
  const results = await page.evaluate(() => axe.run(document, { runOnly: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa", "best-practice"] }));
  await page.close();
  return results.violations.map((violation) => `axe ${violation.id}: ${violation.help} (${violation.nodes.length})`);
}

async function lighthouseFailures(browser, url) {
  const port = Number(new URL(browser.wsEndpoint()).port);
  const { lhr } = await lighthouse(url, { port, output: "json", logLevel: "error", onlyCategories: ["accessibility", "seo", "best-practices"] });
  return Object.values(lhr.categories).filter((category) => category.score < threshold).map((category) => `lighthouse ${category.id}: ${category.score}`);
}

async function main() {
  const server = await serve();
  const base = `http://localhost:${server.address().port}`;
  const browser = await puppeteer.launch({ executablePath: chromePath, headless: true });
  let failureCount = 0;
  // AUDIT_FILTER: comma-separated substrings (page must include at least one). "/" matches only the
  // home page exactly; a leading "=" requires an exact match (e.g. "=/en/help/" for just the hub page).
  const filters = (process.env.AUDIT_FILTER ?? "").split(",").filter(Boolean);
  const matches = (page, filter) => (filter === "/" || filter.startsWith("=") ? page === filter.replace(/^=/, "") : page.includes(filter));
  for (const path of pagePaths().filter((page) => filters.length === 0 || filters.some((filter) => matches(page, filter)))) {
    const html = readFileSync(join(siteDir, path, "index.html"), "utf8");
    const failures = [...validateJsonLd(html), ...(await axeViolations(browser, base + path)), ...(await lighthouseFailures(browser, base + path))];
    failureCount += failures.length;
    console.log(`${failures.length === 0 ? "✔" : "✖"} ${path}`);
    failures.forEach((failure) => console.log(`    ${failure}`));
  }
  await browser.close();
  server.close();
  process.exit(failureCount === 0 ? 0 : 1);
}

main();
