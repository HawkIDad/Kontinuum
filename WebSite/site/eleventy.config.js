// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Eleventy config — content lives in ../content, output in ./_site (host-agnostic).
import { readFileSync } from "node:fs";
import markdownIt from "markdown-it";
import { addFilters } from "./scripts/filters.js";
import { addShortcodes } from "./scripts/shortcodes.js";

const featureMap = JSON.parse(readFileSync(new URL("./_data/featureMap.json", import.meta.url), "utf8"));

export default function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy({ "../content/en/_assets": "en/_assets", "./assets": "assets" });
  eleventyConfig.addCollection("helpPages", (api) => api.getFilteredByGlob("../content/en/help/*/*.md"));

  // Sample pages (one per layout) are built only for audits: SAMPLES=1 npm run build
  if (!process.env.SAMPLES) eleventyConfig.ignores.add("../content/_samples/**");

  addFilters(eleventyConfig, featureMap);
  addShortcodes(eleventyConfig, markdownIt({ html: true }));

  return {
    dir: {
      input: "../content",
      includes: "../site/_includes",
      data: "../site/_data",
      output: "_site",
    },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
  };
}
