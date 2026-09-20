// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Single source of truth: the in-app legal text (NoteBytez/Resources/Legal). The site renders it so
// the website and the app can never drift apart.
import { readFileSync } from "node:fs";
import markdownIt from "markdown-it";

const legalDir = new URL("../../../NoteBytez/Resources/Legal/", import.meta.url);
const markdown = markdownIt({ html: false });

function loadDocument(fileName) {
  const source = readFileSync(new URL(fileName, legalDir), "utf8");
  const versionLine = /\*\*Version ([\d.]+) · Last Updated: ([^*]+)\*\*/.exec(source);
  const body = source
    .replace(/^# .*\n+/, "")
    .replace(/\*\*Version [^\n]*\n+/, "");
  return {
    version: versionLine?.[1] ?? "",
    lastUpdated: versionLine?.[2].trim() ?? "",
    html: markdown.render(body),
  };
}

export default {
  privacy: loadDocument("NoteBytez-Data-Use-Policy-v1.0.md"),
  terms: loadDocument("NoteBytez-EULA-v1.0.md"),
};
