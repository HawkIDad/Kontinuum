// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Category hubs at /en/help/<category>/: the feature-map categories plus the persona journeys.
import { readFileSync } from "node:fs";

const featureMap = JSON.parse(readFileSync(new URL("./featureMap.json", import.meta.url), "utf8"));

export default [
  ...featureMap.categories.map(({ slug, title }) => ({ slug, title })),
  { slug: "journeys", title: "Journeys" },
];
