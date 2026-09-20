// © Copyright, 2026 David L. Collison, All Rights Reserved.
import test from "node:test";
import assert from "node:assert/strict";
import { faqFromHeadings } from "../scripts/filters.js";

test("faq: question headings with a following paragraph become Q&A pairs", () => {
  const html = '<h2 id="a">What is it?</h2>\n<p>It is <strong>a thing</strong>.</p>\n<h2>Not a question</h2>\n<p>skip</p>\n<h2>Is it safe?</h2>\n<ul><li>no paragraph first</li></ul><p>later</p>';
  assert.deepEqual(faqFromHeadings(html), [{ q: "What is it?", a: "It is a thing." }]);
});
