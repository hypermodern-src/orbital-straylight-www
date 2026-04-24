#!/usr/bin/env bun
/**
 * SSG Build Script for REINIT // DX
 *
 * Compiles PureScript and injects pre-rendered HTML into index.html
 * for faster FCP and better SEO.
 *
 * Usage:
 *   bun script/ssg.ts         # Full build (compile + bundle + inject)
 *   bun script/ssg.ts --quick # Just inject (assumes already compiled)
 */

import { $ } from "bun";

const root = import.meta.dir + "/..";
const publicDir = root + "/public";
const indexPath = publicDir + "/index.html";
const ssgBundlePath = publicDir + "/ssg-bundle.js";

const quick = process.argv.includes("--quick");

async function build() {
  if (!quick) {
    console.log("Compiling PureScript...");
    await $`spago build`.cwd(root);

    console.log("Bundling SSG module...");
    await $`spago bundle --module Reinit.SSG --outfile ${ssgBundlePath} --platform node --bundle-type module`.cwd(
      root,
    );
  }

  console.log("Rendering static HTML...");

  // Import the bundled module
  const ssg = await import(ssgBundlePath);
  const rendered: string = ssg.renderStatic;

  if (!rendered || rendered.length < 100) {
    throw new Error("SSG render returned empty or invalid HTML");
  }

  console.log(`  Rendered ${rendered.length} chars`);

  // Read current index.html
  const html = await Bun.file(indexPath).text();

  // Check if already has pre-rendered content
  const appDivPattern = /<div id="app">([\s\S]*?)<\/div>\s*<script/;
  const appDiv = html.match(appDivPattern);
  if (!appDiv) {
    throw new Error("Could not find #app div in index.html");
  }

  const currentContent = appDiv[1].trim();
  const hasContent = currentContent.length > 0;

  if (hasContent) {
    console.log("  Replacing existing pre-rendered content");
  } else {
    console.log("  Injecting pre-rendered content");
  }

  // Inject/replace the pre-rendered HTML
  const replacePattern = /<div id="app">([\s\S]*?)<\/div>(\s*<script)/;
  const updated = html.replace(
    replacePattern,
    `<div id="app">${rendered}</div>$2`,
  );

  await Bun.write(indexPath, updated);

  // Clean up SSG bundle
  await $`rm -f ${ssgBundlePath}`.quiet();

  if (!quick) {
    console.log("Bundling main app...");
    await $`spago bundle`.cwd(root);
  }

  console.log("Done!");
}

build().catch((e) => {
  console.error("SSG build failed:", e);
  process.exit(1);
});
