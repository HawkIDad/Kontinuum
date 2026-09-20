// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Usage: node exportShots.mjs <attachmentsDir> <assetsRoot> <iphone|mac>
// Copies attachments named <category>__<name>__<device>-<appearance> out of an exported .xcresult and
// resizes them to the W4 convention (iPhone 400/800 px wide, Mac 800/1600).
import { readFileSync, mkdirSync, copyFileSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join } from "node:path";

const [attachmentsDir, assetsRoot, device] = process.argv.slice(2);
const oneXWidth = device === "mac" ? 800 : 400;
const manifest = JSON.parse(readFileSync(join(attachmentsDir, "manifest.json"), "utf8"));
const written = new Set();

for (const test of manifest) {
  for (const attachment of test.attachments) {
    const match = /^([a-z0-9-]+)__([a-z0-9-]+)__(iphone|mac)-(light|dark)/.exec(attachment.suggestedHumanReadableName);
    if (!match || match[3] !== device) continue;
    const [, category, name, , appearance] = match;
    const directory = join(assetsRoot, category);
    mkdirSync(directory, { recursive: true });
    const base = join(directory, `${name}-${device}-${appearance}`);
    copyFileSync(join(attachmentsDir, attachment.exportedFileName), `${base}.native.png`);
    execFileSync("sips", ["--resampleWidth", String(oneXWidth * 2), `${base}.native.png`, "--out", `${base}@2x.png`], { stdio: "ignore" });
    execFileSync("sips", ["--resampleWidth", String(oneXWidth), `${base}.native.png`, "--out", `${base}.png`], { stdio: "ignore" });
    rmSync(`${base}.native.png`);
    written.add(`${category}/${name}-${device}-${appearance}`);
  }
}
console.log(`${written.size} screenshots exported`);
[...written].sort().forEach((shot) => console.log(`  ✔ ${shot}`));
