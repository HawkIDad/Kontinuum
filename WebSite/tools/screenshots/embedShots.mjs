// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Inserts {% screenshot %} figures into Help pages (before "## Expected result") for every shot in
// embeds.json whose iPhone-light image exists. Idempotent: skips figures already present.
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const content = join(here, "../../content/en");
const embeds = JSON.parse(readFileSync(join(here, "embeds.json"), "utf8"));
let inserted = 0;
const missing = [];

for (const { shot, page, alt, caption } of embeds) {
  const [category, name] = shot.split("/");
  const image = `${category}/${name}-iphone-light.png`;
  if (!existsSync(join(content, "_assets", image))) { missing.push(shot); continue; }
  const file = join(content, "help", `${page}.md`);
  const text = readFileSync(file, "utf8");
  const figure = `{% screenshot "${image}", "${alt}", "${caption}" %}`;
  if (text.includes(`"${image}"`)) continue;
  writeFileSync(file, text.replace("\n## Expected result", `\n${figure}\n\n## Expected result`));
  inserted += 1;
}
console.log(`${inserted} figures inserted; ${missing.length} shots not captured yet${missing.length ? ": " + missing.join(", ") : ""}`);
