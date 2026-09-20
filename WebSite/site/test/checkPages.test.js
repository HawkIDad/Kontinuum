// © Copyright, 2026 David L. Collison, All Rights Reserved.
import test from "node:test";
import assert from "node:assert/strict";
import { missingFooterLinks, hasAppStoreCta } from "../scripts/checkPages.js";

test("footer: reports each missing legal/support link", () => {
  const html = '<footer><a href="/privacy/">Privacy</a></footer>';
  assert.deepEqual(missingFooterLinks(html), ["/terms/", "/support/"]);
});

test("footer: complete footer passes", () => {
  const html = '<footer><a href="/privacy/"></a><a href="/terms/"></a><a href="/support/"></a></footer>';
  assert.deepEqual(missingFooterLinks(html), []);
});

test("cta: detects the App Store link", () => {
  assert.equal(hasAppStoreCta('<a href="https://x/app">', "https://x/app"), true);
  assert.equal(hasAppStoreCta("<a>", "https://x/app"), false);
});
