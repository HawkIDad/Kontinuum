// © Copyright, 2026 David L. Collison, All Rights Reserved.
import test from "node:test";
import assert from "node:assert/strict";
import { validateFeatureMap, validateFrontMatter, validateNav, findHelpReferences, validateHelpReferences } from "../scripts/checkIA.js";

const validHelp = {
  title: "T", description: "D", category: "linking", order: 1, appliesTo: ["1.0"],
  personas: ["New Arrival"], featureSlug: "wikilinks", lastReviewed: "2026-09-19", type: "howto",
};

test("feature map: duplicate featureSlug is reported", () => {
  const map = { categories: [{ slug: "a", title: "A", features: [["x", "same"], ["y", "same"]] }], journeys: [] };
  assert.match(validateFeatureMap(map).join(), /duplicate featureSlug: same/);
});

test("feature map: category without features is reported", () => {
  const map = { categories: [{ slug: "a", title: "A", features: [] }], journeys: [] };
  assert.match(validateFeatureMap(map).join(), /no features/);
});

test("feature map: invalid slug format is reported", () => {
  const map = { categories: [{ slug: "a", title: "A", features: [["x", "Bad Slug"]] }], journeys: [] };
  assert.match(validateFeatureMap(map).join(), /invalid slug/);
});

test("front matter: valid help page passes", () => {
  assert.deepEqual(validateFrontMatter(validHelp, "help"), []);
});

test("front matter: help page missing featureSlug fails", () => {
  const { featureSlug, ...rest } = validHelp;
  assert.match(validateFrontMatter(rest, "help").join(), /featureSlug/);
});

test("front matter: marketing page requires title and layout", () => {
  assert.notDeepEqual(validateFrontMatter({ title: "x" }, "marketing"), []);
  assert.deepEqual(validateFrontMatter({ title: "x", layout: "base.njk" }, "marketing"), []);
});

test("nav: marketing page missing from nav and footer is reported", () => {
  const nav = { primary: [{ title: "Home", url: "/" }], footer: [] };
  assert.match(validateNav(nav, ["/", "/pricing/"]).join(), /\/pricing\//);
});

const map = { categories: [{ slug: "linking", title: "L", features: [["W", "wikilinks"]] }], journeys: [] };

test("help references: shortcode and front-matter forms are both found", () => {
  const text = '{% helpLink "linking", "wikilinks", "x" %}\nhelp: linking/wikilinks\n';
  assert.deepEqual(findHelpReferences(text), [["linking", "wikilinks"], ["linking", "wikilinks"]]);
});

test("help references: unknown slug is reported, known slug passes", () => {
  assert.deepEqual(validateHelpReferences([["linking", "wikilinks"]], map, "p.md"), []);
  assert.match(validateHelpReferences([["linking", "nope"]], map, "p.md").join(), /p.md: unknown help page linking\/nope/);
});
