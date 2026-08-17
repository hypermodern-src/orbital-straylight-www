#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import { basename, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const projectDir = dirname(dirname(fileURLToPath(import.meta.url)));
const manifestPath = process.env.ORBITAL_PAPERS_MANIFEST ?? join(projectDir, "content", "papers.json");
const arguments_ = process.argv.slice(2);
const publish = arguments_.includes("--publish");
const sourceDir = option("--source-dir");
const apiBase = (option("--api-base") ?? "https://orbital-cms.fly.dev").replace(/\/$/, "");
const supabaseUrl = (process.env.SUPABASE_URL ?? "https://zorahcnswubdvqehhxve.supabase.co").replace(/\/$/, "");
const bucket = process.env.ORBITAL_PAPERS_BUCKET ?? "orbital-publications";
const editorToken = process.env.ORBITAL_CMS_EDITOR_TOKEN;
const storageKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!sourceDir) {
  fail("--source-dir is required");
}
if (publish && !editorToken) {
  fail("ORBITAL_CMS_EDITOR_TOKEN is required with --publish");
}
if (publish && !storageKey) {
  fail("SUPABASE_SERVICE_ROLE_KEY is required with --publish");
}

const papers = JSON.parse(await readFile(manifestPath, "utf8"));
const prepared = [];
const slugs = new Set();

for (const paper of papers) {
  if (slugs.has(paper.slug)) {
    fail(`duplicate paper slug: ${paper.slug}`);
  }
  slugs.add(paper.slug);
  const path = join(sourceDir, paper.file);
  const bytes = await readFile(path);
  const details = await stat(path);
  const sha256 = createHash("sha256").update(bytes).digest("hex");
  if (sha256 !== paper.sha256) {
    fail(`${paper.file}: expected ${paper.sha256}, got ${sha256}`);
  }
  prepared.push({ paper, path, bytes, byteSize: details.size });
}

console.log(`Validated ${prepared.length} canonical PDFs from ${sourceDir}.`);
if (!publish) {
  for (const { paper, byteSize } of prepared) {
    console.log(`ready     ${paper.slug} (${byteSize} bytes, ${paper.sha256.slice(0, 12)})`);
  }
  console.log("Dry run complete. Pass --publish with CMS and Supabase credentials to import.");
  process.exit(0);
}

await ensureBucket();
const existing = await existingDocuments();
let created = 0;
let published = 0;
let skipped = 0;

for (const item of prepared) {
  const { paper } = item;
  const objectKey = `papers/${paper.slug}/${paper.sha256}.pdf`;
  const externalUrl = publicObjectUrl(objectKey);
  await uploadPdf(objectKey, item.bytes);
  const asset = await api("/v1/editorial/assets", {
    method: "POST",
    body: JSON.stringify({
      kind: "pdf",
      object_key: objectKey,
      external_url: externalUrl,
      media_type: "application/pdf",
      byte_size: item.byteSize,
      sha256: paper.sha256,
      caption: paper.title,
      credit: paper.authors.map((author) => author.display_name).join(", "),
      license_spdx: "CC-BY-4.0",
    }),
  });

  let document = existing.get(paper.slug);
  if (document?.workflow_state === "published") {
    console.log(`skip      ${paper.slug} (already published)`);
    skipped += 1;
    continue;
  }
  if (!document) {
    document = await api("/v1/editorial/documents", {
      method: "POST",
      body: JSON.stringify({
        channel: "orbital",
        kind: "paper",
        slug: paper.slug,
        revision: revision(paper, asset.id),
      }),
    });
    existing.set(paper.slug, document);
    console.log(`draft     ${paper.slug}`);
    created += 1;
  }
  if (document.workflow_state !== "draft") {
    fail(`${paper.slug} exists in ${document.workflow_state}; refusing an implicit workflow change`);
  }
  await api(`/v1/editorial/documents/${document.id}/transitions`, {
    method: "POST",
    body: JSON.stringify({
      expected_revision: document.current_revision,
      target: "published",
      published_at: paper.published_at,
    }),
  });
  console.log(`published ${paper.slug} (${paper.published_at.slice(0, 10)})`);
  published += 1;
}

console.log(`Import complete: ${created} created, ${published} published, ${skipped} skipped.`);

function revision(paper, pdfAssetId) {
  const authors = paper.authors.map((author, position) => ({
    ...author,
    position,
    role: "author",
  }));
  return {
    title: paper.title,
    subtitle: paper.subtitle,
    summary: paper.summary,
    body: [
      "## Abstract",
      "",
      paper.summary,
      "",
      "## Artifact",
      "",
      "The complete paper is preserved as a content-addressed PDF. Use the download link above for the canonical artifact.",
      "",
      `SHA-256: \`${paper.sha256}\``,
    ].join("\n"),
    source_format: "markdown",
    language: "en",
    authors,
    tags: paper.tags,
    paper: {
      version_label: paper.version,
      license_spdx: "CC-BY-4.0",
      references_csl: [],
      pdf_asset_id: pdfAssetId,
    },
  };
}

async function existingDocuments() {
  const page = await api("/v1/editorial/documents?channel=orbital&kind=paper&limit=100");
  return new Map(page.items.map((document) => [document.slug, document]));
}

async function api(path, init = {}) {
  const response = await fetch(`${apiBase}${path}`, {
    ...init,
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${editorToken}`,
      "Content-Type": "application/json",
      ...init.headers,
    },
  });
  const text = await response.text();
  if (!response.ok) {
    fail(`${init.method ?? "GET"} ${path}: ${response.status} ${text.slice(0, 1000)}`);
  }
  return text ? JSON.parse(text) : undefined;
}

async function ensureBucket() {
  const found = await storage(`/storage/v1/bucket/${encodeURIComponent(bucket)}`, { method: "GET" }, [200, 400, 404]);
  if (found.status === 200) return;
  await storage("/storage/v1/bucket", {
    method: "POST",
    body: JSON.stringify({
      id: bucket,
      name: bucket,
      public: true,
      file_size_limit: 10485760,
      allowed_mime_types: ["application/pdf"],
    }),
    headers: { "Content-Type": "application/json" },
  });
  console.log(`bucket    ${bucket}`);
}

async function uploadPdf(objectKey, bytes) {
  await storage(`/storage/v1/object/${encodeURIComponent(bucket)}/${encodedPath(objectKey)}`, {
    method: "POST",
    body: bytes,
    headers: {
      "Content-Type": "application/pdf",
      "Cache-Control": "public, max-age=31536000, immutable",
      "x-upsert": "true",
    },
  });
  console.log(`uploaded  ${basename(objectKey)} (${bytes.length} bytes)`);
}

async function storage(path, init, accepted = [200]) {
  const response = await fetch(`${supabaseUrl}${path}`, {
    ...init,
    headers: {
      apikey: storageKey,
      Authorization: `Bearer ${storageKey}`,
      ...init.headers,
    },
  });
  if (!accepted.includes(response.status)) {
    const text = await response.text();
    fail(`${init.method} storage ${path}: ${response.status} ${text.slice(0, 1000)}`);
  }
  return response;
}

function publicObjectUrl(objectKey) {
  return `${supabaseUrl}/storage/v1/object/public/${encodeURIComponent(bucket)}/${encodedPath(objectKey)}`;
}

function encodedPath(path) {
  return path.split("/").map(encodeURIComponent).join("/");
}

function option(name) {
  const index = arguments_.indexOf(name);
  return index === -1 ? undefined : arguments_[index + 1];
}

function fail(message) {
  console.error(`orbital-cms paper import: ${message}`);
  process.exit(1);
}
