#!/usr/bin/env bun

const RSS_URL = "https://www.weyl.ai/plan/rss.xml";
const DEFAULT_CMS_URL = "https://orbital-cms.fly.dev";

const args = Bun.argv.slice(2);
const publish = args.includes("--publish");
const outputIndex = args.indexOf("--output-dir");
const outputDirectory = outputIndex >= 0 ? args[outputIndex + 1] : null;
const cmsUrl = (process.env.ORBITAL_CMS_URL || DEFAULT_CMS_URL).replace(/\/$/, "");
const editorToken = process.env.ORBITAL_CMS_EDITOR_TOKEN;

if (outputIndex >= 0 && !outputDirectory) {
  throw new Error("--output-dir requires a path");
}
if (publish && !editorToken) {
  throw new Error("ORBITAL_CMS_EDITOR_TOKEN is required with --publish");
}

const decodeEntities = (source) => source.replace(
  /&(#x?[0-9a-f]+|[a-z]+);/gi,
  (entity, name) => {
    if (name[0] === "#") {
      const hexadecimal = name[1].toLowerCase() === "x";
      return String.fromCodePoint(Number.parseInt(name.slice(hexadecimal ? 2 : 1), hexadecimal ? 16 : 10));
    }
    return ({ amp: "&", apos: "'", gt: ">", lt: "<", nbsp: " ", quot: '"' })[name.toLowerCase()] || entity;
  },
);

const xmlField = (item, name) => {
  const match = item.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)<\\/${name}>`, "i"));
  if (!match) throw new Error(`RSS item is missing ${name}`);
  return decodeEntities(match[1].replace(/^<!\[CDATA\[/, "").replace(/\]\]>$/, "").trim());
};

const slugify = (source) => {
  const expanded = source.toLowerCase() === "c++" ? "c-plus-plus" : source.toLowerCase();
  return expanded
    .replace(/&/g, "-and-")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
};

const authorRecords = (author) => author
  .split(/\s*\/\s*/)
  .filter(Boolean)
  .map((displayName, position) => ({
    slug: slugify(displayName === "Weyl Team" ? "weyl-team" : displayName),
    display_name: displayName,
    position,
    role: "author",
    affiliation: "Weyl AI",
  }));

const parseFeed = (xml) => [...xml.matchAll(/<item>([\s\S]*?)<\/item>/g)].map((match) => {
  const item = match[1];
  const sourceUrl = xmlField(item, "link");
  const categories = [...item.matchAll(/<category[^>]*>([\s\S]*?)<\/category>/gi)]
    .map((category) => slugify(decodeEntities(category[1].trim())))
    .filter(Boolean);
  return {
    title: xmlField(item, "title"),
    summary: xmlField(item, "description"),
    sourceUrl,
    slug: new URL(sourceUrl).pathname.split("/").filter(Boolean).at(-1),
    publishedAt: new Date(xmlField(item, "pubDate")).toISOString(),
    authors: authorRecords(xmlField(item, "author")),
    tags: [...new Set(categories)],
  };
});

const stripTags = (source) => decodeEntities(source.replace(/<[^>]*>/g, ""));
const escapeHtml = (source) => source
  .replace(/&/g, "&amp;")
  .replace(/</g, "&lt;")
  .replace(/>/g, "&gt;");

const normalizeCodeBlocks = (html) => html.replace(
  /<pre\b([^>]*)>([\s\S]*?)<\/pre>/gi,
  (original, attributes, contents) => {
    const language = attributes.match(/data-language=["']([^"']+)["']/i)?.[1] || "text";
    const lineMatches = [...contents.matchAll(/<div\b[^>]*class=["'][^"']*\bcode\b[^"']*["'][^>]*>([\s\S]*?)<\/div>/gi)];
    if (lineMatches.length === 0) return original;
    const code = lineMatches.map((line) => stripTags(line[1])).join("\n");
    return `<pre><code class="language-${language.replace(/[^a-z0-9_+-]/gi, "")}">${escapeHtml(code)}</code></pre>`;
  },
);

const flattenExpressiveCode = (html) => html.replace(
  /<div\b[^>]*class=["'][^"']*\bexpressive-code\b[^"']*["'][^>]*>([\s\S]*?)<\/figure>\s*<\/div>/gi,
  (original, contents) => contents.match(/<pre\b[^>]*>[\s\S]*?<\/pre>/i)?.[0] || original,
);

const articleBody = (html, sourceUrl) => {
  const article = html.match(/<article\b[^>]*>([\s\S]*?)<\/article>/i)?.[1];
  if (!article) throw new Error(`Could not find article body at ${sourceUrl}`);
  const prose = article.match(/<div\b[^>]*class=["'][^"']*\b(?:prose|straylight-content)\b[^"']*["'][^>]*>([\s\S]*)<\/div>\s*$/i)?.[1];
  if (!prose) throw new Error(`Could not find prose body at ${sourceUrl}`);
  return flattenExpressiveCode(normalizeCodeBlocks(prose))
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, "")
    .replace(/<link\b[^>]*>/gi, "")
    .replace(/<button\b[^>]*class=["'][^"']*copy[^"']*["'][^>]*>[\s\S]*?<\/button>/gi, "")
    .replace(/\sstyle=["'][^"']*["']/gi, "")
    .replace(/<\/?(?:div|span)\b[^>]*>/gi, "")
    .replace(/<figcaption\b[^>]*>[\s\S]*?<\/figcaption>/gi, "")
    .replace(/<\/?figure\b[^>]*>/gi, "");
};

const toMarkdown = async (html) => {
  const process = Bun.spawn(
    ["pandoc", "--from=html", "--to=gfm", "--wrap=none"],
    { stdin: "pipe", stdout: "pipe", stderr: "pipe" },
  );
  process.stdin.write(html);
  process.stdin.end();
  const [exitCode, stdout, stderr] = await Promise.all([
    process.exited,
    new Response(process.stdout).text(),
    new Response(process.stderr).text(),
  ]);
  if (exitCode !== 0) throw new Error(`pandoc failed: ${stderr.trim()}`);
  return stdout.trim();
};

const canonicalizeLinks = (markdown) => markdown
  .replace(/(\]\()\/(?!\/)/g, "$1https://www.weyl.ai/")
  .replace(/(src=["'])\/(?!\/)/g, "$1https://www.weyl.ai/");

const fetchText = async (url) => {
  const response = await fetch(url, { headers: { "user-agent": "orbital-cms-import/1.0" } });
  if (!response.ok) throw new Error(`${url}: HTTP ${response.status}`);
  return response.text();
};

const api = async (path, options = {}) => {
  const response = await fetch(`${cmsUrl}${path}`, {
    ...options,
    headers: {
      authorization: `Bearer ${editorToken}`,
      "content-type": "application/json",
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  let body;
  try { body = text ? JSON.parse(text) : null; } catch { body = text; }
  if (!response.ok) throw new Error(`${options.method || "GET"} ${path}: HTTP ${response.status} ${JSON.stringify(body)}`);
  return body;
};

const existingDocuments = async () => {
  if (!publish) return new Map();
  const page = await api("/v1/editorial/documents?channel=orbital&kind=post&limit=100");
  return new Map(page.items.map((document) => [document.slug, document]));
};

const rss = await fetchText(RSS_URL);
const posts = parseFeed(rss);
if (posts.length !== 10) throw new Error(`Expected 10 Weyl posts, found ${posts.length}`);

for (const post of posts) {
  const html = await fetchText(post.sourceUrl);
  const markdown = canonicalizeLinks(await toMarkdown(articleBody(html, post.sourceUrl)));
  post.body = `> Originally published by [Weyl AI](${post.sourceUrl}) on ${post.publishedAt.slice(0, 10)}.\n\n${markdown}`;
  if (outputDirectory) await Bun.write(`${outputDirectory}/${post.slug}.md`, `${post.body}\n`);
}

console.log(`Prepared ${posts.length} Weyl .plan posts (${posts.reduce((sum, post) => sum + post.body.length, 0)} Markdown characters).`);

if (!publish) {
  console.log("Dry run complete. Pass --publish with ORBITAL_CMS_EDITOR_TOKEN to import.");
  process.exit(0);
}

const existing = await existingDocuments();
let created = 0;
let published = 0;
let skipped = 0;

for (const post of posts) {
  let document = existing.get(post.slug);
  if (document?.workflow_state === "published") {
    console.log(`skip      ${post.slug} (already published)`);
    skipped += 1;
    continue;
  }
  if (!document) {
    document = await api("/v1/editorial/documents", {
      method: "POST",
      body: JSON.stringify({
        channel: "orbital",
        kind: "post",
        slug: post.slug,
        revision: {
          title: post.title,
          summary: post.summary,
          body: post.body,
          source_format: "markdown",
          language: "en",
          authors: post.authors,
          tags: post.tags,
        },
      }),
    });
    console.log(`draft     ${post.slug}`);
    created += 1;
  }
  if (document.workflow_state !== "draft") {
    throw new Error(`${post.slug} exists in ${document.workflow_state}; refusing an implicit workflow change`);
  }
  await api(`/v1/editorial/documents/${document.id}/transitions`, {
    method: "POST",
    body: JSON.stringify({
      expected_revision: document.current_revision,
      target: "published",
      published_at: post.publishedAt,
    }),
  });
  console.log(`published ${post.slug} (${post.publishedAt.slice(0, 10)})`);
  published += 1;
}

console.log(`Import complete: ${created} created, ${published} published, ${skipped} skipped.`);
