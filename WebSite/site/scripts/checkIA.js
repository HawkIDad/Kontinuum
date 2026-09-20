// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Information-architecture lint (W2): feature map, nav coverage, front-matter schema.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import Ajv2020 from "ajv/dist/2020.js";
import matter from "gray-matter";
import { validateHowToStructure } from "./checkContent.js";

const slugPattern = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const marketingUrls = ["/", "/features/", "/pricing/", "/support/", "/privacy/", "/terms/"];
const dataDir = join(dirname(fileURLToPath(import.meta.url)), "..", "_data");
const contentDir = join(dataDir, "..", "..", "content");

const ajv = new Ajv2020({ allErrors: true });
const schemas = {
  help: ajv.compile(readJson("helpFrontMatter.schema.json")),
  marketing: ajv.compile(readJson("marketingFrontMatter.schema.json")),
};

function readJson(fileName) {
  return JSON.parse(readFileSync(join(dataDir, fileName), "utf8"));
}

export function validateFeatureMap(featureMap) {
  const errors = [];
  const seenSlugs = new Set();
  for (const category of featureMap.categories) {
    if (!slugPattern.test(category.slug)) errors.push(`invalid slug: category ${category.slug}`);
    if (category.features.length === 0) errors.push(`category ${category.slug} has no features`);
    for (const [feature, slug] of category.features) {
      if (!slugPattern.test(slug)) errors.push(`invalid slug: ${slug} (${feature})`);
      if (seenSlugs.has(slug)) errors.push(`duplicate featureSlug: ${slug}`);
      seenSlugs.add(slug);
    }
  }
  for (const journey of featureMap.journeys) {
    if (!slugPattern.test(journey.slug)) errors.push(`invalid slug: journey ${journey.slug}`);
  }
  return errors;
}

export function validateFrontMatter(data, kind) {
  const validate = schemas[kind];
  if (validate(data)) return [];
  return validate.errors.map((error) => `${error.instancePath || "/"} ${error.message} ${JSON.stringify(error.params)}`);
}

export function validateNav(nav, requiredUrls) {
  const linkedUrls = new Set([...nav.primary, ...nav.footer].map((item) => item.url));
  return requiredUrls.filter((url) => !linkedUrls.has(url)).map((url) => `page not in nav or footer: ${url}`);
}

export function findHelpReferences(text) {
  const shortcodes = [...text.matchAll(/helpLink\s+"([^"]+)",\s*"([^"]+)"/g)].map((match) => [match[1], match[2]]);
  const frontMatter = [...text.matchAll(/^\s*help:\s*([a-z0-9-]+)\/([a-z0-9-]+)\s*$/gm)].map((match) => [match[1], match[2]]);
  return [...shortcodes, ...frontMatter];
}

export function validateHelpReferences(references, featureMap, fileName) {
  const known = new Set(featureMap.categories.flatMap((category) => category.features.map(([, slug]) => `${category.slug}/${slug}`)));
  return references
    .filter(([category, slug]) => !known.has(`${category}/${slug}`))
    .map(([category, slug]) => `${fileName}: unknown help page ${category}/${slug}`);
}

function markdownFiles(directory) {
  return readdirSync(directory).flatMap((name) => {
    const path = join(directory, name);
    if (statSync(path).isDirectory()) return name.startsWith("_") ? [] : markdownFiles(path);
    return name.endsWith(".md") ? [path] : [];
  });
}

function validateContent(featureMap) {
  return markdownFiles(contentDir).flatMap((path) => {
    const relativePath = relative(contentDir, path);
    const helpErrors = validateHelpReferences(findHelpReferences(readFileSync(path, "utf8")), featureMap, relativePath);
    const isHelpArticle = relativePath.startsWith(join("en", "help")) && !relativePath.endsWith("index.md");
    const kind = isHelpArticle ? "help" : "marketing";
    const frontMatterErrors = validateFrontMatter(matter.read(path).data, kind).map((error) => `${relativePath}: ${error}`);
    const parsed = matter.read(path);
    const structureErrors = isHelpArticle && parsed.data.type === "howto" ? validateHowToStructure(parsed.content, relativePath) : [];
    return [...frontMatterErrors, ...helpErrors, ...structureErrors];
  });
}

function main() {
  const featureMap = readJson("featureMap.json");
  const errors = [
    ...validateFeatureMap(featureMap),
    ...validateNav(readJson("nav.json"), marketingUrls),
    ...validateContent(featureMap),
  ];
  errors.forEach((error) => console.error(`✖ ${error}`));
  if (errors.length > 0) process.exit(1);
  console.log("✔ IA lint clean");
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
