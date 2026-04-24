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

  // Find the app div boundaries more precisely
  // Look for: <div id="app">...</div> followed by newline and <script
  const appStart = html.indexOf('<div id="app">');
  if (appStart === -1) {
    throw new Error("Could not find #app div start");
  }

  // Find the </div> that precedes <script src="/reinit.js">
  const scriptTag = '<script src="/reinit.js">';
  const scriptStart = html.indexOf(scriptTag);
  if (scriptStart === -1) {
    throw new Error("Could not find reinit.js script tag");
  }

  // The </div> we want is right before the script tag (with possible whitespace)
  // Work backwards from scriptStart to find </div>
  const beforeScript = html.slice(0, scriptStart);
  const lastDivClose = beforeScript.lastIndexOf("</div>");
  if (lastDivClose === -1) {
    throw new Error("Could not find closing </div> before script");
  }

  // The content between <div id="app"> and that </div>
  const appOpenEnd = appStart + '<div id="app">'.length;

  // Build the new HTML
  const before = html.slice(0, appOpenEnd);
  const after = html.slice(lastDivClose);

  const updated = before + rendered + after;

  // Sanity check - the new file shouldn't be drastically larger
  const sizeDiff = updated.length - html.length;
  if (sizeDiff > 100000) {
    throw new Error(
      `Output seems too large (${sizeDiff} bytes larger). Aborting.`,
    );
  }

  await Bun.write(indexPath, updated);
  console.log(`  Wrote ${updated.length} bytes`);

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
