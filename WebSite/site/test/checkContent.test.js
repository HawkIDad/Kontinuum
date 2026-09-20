// © Copyright, 2026 David L. Collison, All Rights Reserved.
import test from "node:test";
import assert from "node:assert/strict";
import { validateHowToStructure, findScreenshotRefs, validateScreenshotRefs } from "../scripts/checkContent.js";
import { extractInternalLinks, findBrokenLinks, findOrphans } from "../scripts/checkLinks.js";

const good = "## Purpose\n\nx\n\n## Prerequisites\n\ny\n\n## Steps\n\n1. a\n2. b\n\n## Expected result\n\nz\n\n## Related\n\n- l\n";

test("how-to structure: complete article passes", () => {
  assert.deepEqual(validateHowToStructure(good, "p.md"), []);
});

test("how-to structure: missing and misordered sections are reported", () => {
  assert.match(validateHowToStructure(good.replace("## Prerequisites\n\ny\n\n", ""), "p.md").join(), /missing section: Prerequisites/);
  const swapped = good.replace("## Purpose", "## Related X").replace("## Related\n", "## Purpose\n");
  assert.notDeepEqual(validateHowToStructure(swapped, "p.md"), []);
});

test("how-to structure: Steps must contain a numbered list", () => {
  assert.match(validateHowToStructure(good.replace("1. a\n2. b", "just prose"), "p.md").join(), /Steps must be a numbered list/);
});

test("links: internal hrefs are extracted, external and anchors ignored", () => {
  const html = '<a href="/a/">a</a><a href="https://x.com">x</a><a href="#top">t</a><a href="/b/#frag">b</a>';
  assert.deepEqual(extractInternalLinks(html), ["/a/", "/b/"]);
});

test("links: broken links and orphans are found", () => {
  const pages = new Map([["/a/", ["/b/", "/missing/"]], ["/b/", []], ["/c/", []]]);
  assert.deepEqual(findBrokenLinks(pages), [["/a/", "/missing/"]]);
  assert.deepEqual(findOrphans(pages, ["/a/", "/b/", "/c/"]).sort(), ["/a/", "/c/"]);
});

test("screenshots: references are found and each needs a 1x, @2x and dark variant", () => {
  const text = '{% screenshot "tags/tag-browser-iphone-light.png", "alt", "cap" %}';
  assert.deepEqual(findScreenshotRefs(text), ["tags/tag-browser-iphone-light.png"]);
  const present = new Set(["tags/tag-browser-iphone-light.png", "tags/tag-browser-iphone-light@2x.png", "tags/tag-browser-iphone-dark.png", "tags/tag-browser-iphone-dark@2x.png"]);
  assert.deepEqual(validateScreenshotRefs(["tags/tag-browser-iphone-light.png"], (file) => present.has(file), "p.md"), []);
  present.delete("tags/tag-browser-iphone-dark@2x.png");
  assert.match(validateScreenshotRefs(["tags/tag-browser-iphone-light.png"], (file) => present.has(file), "p.md").join(), /missing image: tags\/tag-browser-iphone-dark@2x.png/);
});
