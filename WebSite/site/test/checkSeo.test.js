// © Copyright, 2026 David L. Collison, All Rights Reserved.
import test from "node:test";
import assert from "node:assert/strict";
import { checkPageSeo, sitemapUrls, llmsLinks, robotsHasSitemap } from "../scripts/checkSeo.js";

const goodPage = `<!doctype html><html lang="en"><head><title>T · NoteBytez</title>
<meta name="description" content="${"d".repeat(80)}"><link rel="canonical" href="https://x.test/a/">
<meta property="og:title" content="T"><meta property="og:description" content="d"><meta property="og:url" content="https://x.test/a/">
<meta name="twitter:card" content="summary"></head><body><main><h1>T</h1><p>${"word ".repeat(30)}</p></main></body></html>`;

test("page seo: a complete page passes", () => {
  assert.deepEqual(checkPageSeo(goodPage, "/a/"), []);
});

test("page seo: reports missing canonical, second h1, short description and thin content", () => {
  const bad = goodPage.replace(/<link rel="canonical"[^>]*>/, "").replace("<h1>T</h1>", "<h1>T</h1><h1>U</h1>").replace(/content="d{80}"/, 'content="short"').replace(/word /g, "");
  const errors = checkPageSeo(bad, "/a/").join();
  assert.match(errors, /canonical/);
  assert.match(errors, /exactly one h1/);
  assert.match(errors, /description/);
  assert.match(errors, /no readable content/);
});

test("sitemap, llms and robots parsing", () => {
  assert.deepEqual(sitemapUrls("<urlset><url><loc>https://x.test/a/</loc></url><url><loc>https://x.test/b/</loc></url></urlset>"), ["https://x.test/a/", "https://x.test/b/"]);
  assert.deepEqual(llmsLinks("# T\n- [A](https://x.test/a/): desc\n- [B](https://x.test/b/)"), ["https://x.test/a/", "https://x.test/b/"]);
  assert.equal(robotsHasSitemap("User-agent: *\nSitemap: https://x.test/sitemap.xml"), true);
  assert.equal(robotsHasSitemap("User-agent: *"), false);
});
