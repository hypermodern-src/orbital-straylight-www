import { cpSync, existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const build = join(root, ".build");
const dist = join(root, "dist");
const spago = join(root, "node_modules", ".bin", "spago");

const run = (command, args, options = {}) => {
  const result = spawnSync(command, args, { cwd: root, stdio: "inherit", ...options });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
  return result;
};

if (!existsSync(spago)) {
  throw new Error("reinit-dx: missing local tools; run npm ci first");
}

rmSync(build, { recursive: true, force: true });
rmSync(dist, { recursive: true, force: true });
mkdirSync(build, { recursive: true });
mkdirSync(dist, { recursive: true });

run(spago, [
  "bundle",
  "--module", "Reinit.SSG",
  "--platform", "node",
  "--bundle-type", "module",
  "--outfile", join(build, "reinit-ssg.mjs"),
  "--strict",
]);

const rendered = run(
  process.execPath,
  [
    "-e",
    "import('./.build/reinit-ssg.mjs').then((m) => m.main())",
    join(root, "public", "index.html"),
  ],
  { encoding: "utf8", stdio: ["ignore", "pipe", "inherit"] },
).stdout;

if (!rendered.includes('<div id="app">') || !rendered.includes("REINIT // DX")) {
  throw new Error("reinit-dx: static renderer produced an invalid document");
}
writeFileSync(join(dist, "index.html"), rendered, "utf8");

run(spago, [
  "bundle",
  "--module", "Main",
  "--platform", "browser",
  "--bundle-type", "app",
  "--outfile", join(dist, "reinit.js"),
  "--minify",
  "--strict",
]);

for (const entry of readdirSync(join(root, "public"))) {
  if (entry !== "index.html" && entry !== "reinit.js") {
    cpSync(join(root, "public", entry), join(dist, entry), { recursive: true });
  }
}

if (process.argv.includes("--vercel")) {
  const vercelOutput = join(root, ".vercel", "output");
  rmSync(vercelOutput, { recursive: true, force: true });
  mkdirSync(join(vercelOutput, "static"), { recursive: true });
  for (const entry of readdirSync(dist)) {
    cpSync(join(dist, entry), join(vercelOutput, "static", entry), { recursive: true });
  }
  writeFileSync(join(vercelOutput, "config.json"), '{ "version": 3 }\n', "utf8");
  console.log(`reinit-dx: Vercel output -> ${vercelOutput}`);
}

console.log(`reinit-dx: static site -> ${dist}`);
