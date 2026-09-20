// © Copyright, 2026 David L. Collison, All Rights Reserved.
// Shortcodes: admonition, screenshot figure, persona chip, Features → Help deep link.

// Lucide (ISC) icon paths; decorative, so aria-hidden.
const icons = {
  note: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  tip: '<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"/><path d="M9 18h6"/><path d="M10 22h4"/>',
  warning: '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
};
const labels = { note: "Note", tip: "Tip", warning: "Warning" };

const escape = (text) => String(text).replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;");

export function addShortcodes(eleventyConfig, markdown) {
  eleventyConfig.addPairedShortcode("admonition", (content, kind = "note") => {
    const type = icons[kind] ? kind : "note";
    return `<aside class="admonition admonition-${type}" role="note" aria-label="${labels[type]}">
<p class="admonition-label"><svg aria-hidden="true" focusable="false" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${icons[type]}</svg><strong>${labels[type]}</strong></p>
${markdown.render(content)}</aside>`;
  });

  // path is relative to /en/_assets/; a 2x asset is expected at <name>@2x.<ext>
  eleventyConfig.addShortcode("screenshot", (path, alt, caption) => {
    const src = `/en/_assets/${path}`;
    const retina = src.replace(/(\.\w+)$/, "@2x$1");
    return `<figure class="screenshot"><img src="${src}" srcset="${src} 1x, ${retina} 2x" alt="${escape(alt)}" loading="lazy" decoding="async"><figcaption>${escape(caption)}</figcaption></figure>`;
  });

  eleventyConfig.addShortcode("personaChip", (persona) => `<span class="persona-chip">${escape(persona)}</span>`);

  eleventyConfig.addShortcode("helpLink", (category, slug, text) => `<a class="help-link" href="/en/help/${category}/${slug}/">${escape(text)}</a>`);
}
