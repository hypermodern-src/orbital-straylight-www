import { cpSync, existsSync, mkdirSync, readdirSync, rmSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const build = join(root, ".build");
const dist = join(root, "dist");
const spago = join(root, "node_modules", ".bin", "spago");

const run = (command, args) => {
  const result = spawnSync(command, args, { cwd: root, stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
};

if (!existsSync(spago)) {
  throw new Error("orbital-web: missing local tools; run npm ci first");
}

rmSync(build, { recursive: true, force: true });
rmSync(dist, { recursive: true, force: true });
mkdirSync(build, { recursive: true });
mkdirSync(dist, { recursive: true });

run(spago, [
  "bundle",
  "--module", "Orbital.SSG",
  "--platform", "node",
  "--bundle-type", "module",
  "--outfile", join(build, "orbital-ssg.mjs"),
  "--strict",
]);

run(process.execPath, [
  "-e",
  "import('./.build/orbital-ssg.mjs').then((m) => m.main())",
  dist,
]);

run(spago, [
  "bundle",
  "--module", "Orbital.Publications.Client",
  "--platform", "browser",
  "--bundle-type", "app",
  "--outfile", join(dist, "publications.js"),
  "--minify",
  "--strict",
]);

const assets = [
  "favicon.svg",
  "fonts.css",
  "fonts",
  "halogen-orbital",
  "robots.txt",
  "scripts",
  "sitemap.xml",
  "styles",
  "waitlist.css",
  "waitlist.js",
];

for (const asset of assets) {
  cpSync(join(root, asset), join(dist, asset), { recursive: true });
}

const requiredPages = [
  "index.html",
  "cache.html",
  "build.html",
  "infer.html",
  "pricing.html",
  "verification.html",
  "journal.html",
  "papers.html",
  "publication.html",
  "about.html",
  "thanks.html",
];

for (const page of requiredPages) {
  const output = join(dist, page);
  if (!existsSync(output) || statSync(output).size === 0) {
    throw new Error(`orbital-web: generator did not produce ${page}`);
  }
}

if (process.argv.includes("--vercel")) {
  const vercelOutput = join(root, ".vercel", "output");
  rmSync(vercelOutput, { recursive: true, force: true });
  mkdirSync(join(vercelOutput, "static"), { recursive: true });
  for (const entry of readdirSync(dist)) {
    cpSync(join(dist, entry), join(vercelOutput, "static", entry), { recursive: true });
  }
  cpSync(join(root, "nix", "vercel-output-config.json"), join(vercelOutput, "config.json"));
  console.log(`orbital-web: Vercel output -> ${vercelOutput}`);
}

console.log(`orbital-web: ${requiredPages.length} routes -> ${dist}`);
