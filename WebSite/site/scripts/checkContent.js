// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Article Standard structure lint for how-to pages (Wiki SF1). "Applies to" is the layout's badge
// (driven by front matter), so the body carries the other five sections.
const requiredSections = ["Purpose", "Prerequisites", "Steps", "Expected result", "Related"];

export function validateHowToStructure(body, fileName) {
  const errors = [];
  const headings = [...body.matchAll(/^## (.+)$/gm)].map((match) => ({ name: match[1].trim(), index: match.index }));
  const positions = requiredSections.map((section) => headings.find((heading) => heading.name === section));

  requiredSections.forEach((section, i) => {
    if (!positions[i]) errors.push(`${fileName}: missing section: ${section}`);
  });
  const found = positions.filter(Boolean);
  if (found.some((position, i) => i > 0 && position.index < found[i - 1].index)) {
    errors.push(`${fileName}: sections out of order (expected ${requiredSections.join(" → ")})`);
  }

  const steps = positions[2];
  if (steps) {
    const next = headings.find((heading) => heading.index > steps.index);
    const stepsText = body.slice(steps.index, next?.index ?? body.length);
    if (!/^\s*1\. /m.test(stepsText)) errors.push(`${fileName}: Steps must be a numbered list`);
  }
  return errors;
}

export function findScreenshotRefs(text) {
  return [...text.matchAll(/\{% screenshot "([^"]+)"/g)].map((match) => match[1]);
}

/** Every referenced figure needs 1x + @2x, and the dark pair when the reference is a "-light" image. */
export function validateScreenshotRefs(references, fileExists, fileName) {
  return references.flatMap((reference) => {
    const variants = [reference, reference.replace(/(\.\w+)$/, "@2x$1")];
    if (reference.includes("-light.")) variants.push(...variants.map((file) => file.replace("-light", "-dark")));
    return variants.filter((file) => !fileExists(file)).map((file) => `${fileName}: missing image: ${file}`);
  });
}

export function findPluginSampleRefs(text) {
  return [...text.matchAll(/\{% pluginSample "([^"]+)"/g)].map((match) => match[1]);
}

/** Every `pluginSample` reference needs its script under content/en/_plugin-samples/. */
export function validatePluginSampleRefs(references, fileExists, fileName) {
  return references.filter((name) => !fileExists(`${name}.js`)).map((name) => `${fileName}: missing plugin sample: ${name}.js`);
}
