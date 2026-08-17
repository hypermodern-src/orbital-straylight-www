import { copyFileSync, mkdirSync, rmSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const examples = {
  gallery: {
    directory: "examples",
    module: "Gallery.Main",
    output: "testing/playwright/.gallery-dist",
    stylesheet: "gallery.css"
  },
  "themes-port": {
    directory: "examples/themes-port",
    module: "ThemesPort.Main",
    output: "testing/playwright/.themes-port-dist",
    stylesheet: "themes.css"
  },
  "themes-interactive": {
    directory: "examples/themes-interactive",
    module: "ThemesInteractive.Main",
    output: "testing/playwright/.themes-interactive-dist",
    stylesheet: "themes.css"
  }
};

const [name, ...arguments_] = process.argv.slice(2);
const example = examples[name];
if (!example) {
  throw new Error(`unknown Hydrogen example: ${name ?? "<missing>"}`);
}

const outputFlag = arguments_.indexOf("--out");
const output = resolve(
  root,
  outputFlag === -1 ? example.output : arguments_[outputFlag + 1]
);
const source = resolve(root, example.directory);
const spago = resolve(root, "node_modules/.bin/spago");

rmSync(output, { recursive: true, force: true });
mkdirSync(output, { recursive: true });

const result = spawnSync(
  spago,
  [
    "bundle",
    "--module",
    example.module,
    "--platform",
    "browser",
    "--bundle-type",
    "app",
    "--outfile",
    join(output, "app.js"),
    "--minify",
    "--strict"
  ],
  { cwd: source, stdio: "inherit" }
);
if (result.status !== 0) process.exit(result.status ?? 1);

copyFileSync(join(source, "index.html"), join(output, "index.html"));
copyFileSync(join(source, example.stylesheet), join(output, "style.css"));
console.log(`hydrogen: bundled ${name} with Spago -> ${output}`);
