import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const build = join(root, ".build");
const dist = join(root, "dist");
const spago = join(root, "node_modules", ".bin", "spago");
const orbitalAssets = join(root, "..", "hydrogen", "assets", "orbital");

const run = (command, args) => {
  const result = spawnSync(command, args, { cwd: root, stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
};

if (!existsSync(spago)) throw new Error("orbital-forge: missing local tools; run npm ci first");
if (!existsSync(orbitalAssets)) throw new Error("orbital-forge: Hydrogen ORBITAL assets are missing");

rmSync(build, { recursive: true, force: true });
rmSync(dist, { recursive: true, force: true });
mkdirSync(build, { recursive: true });
mkdirSync(dist, { recursive: true });

run(spago, [
  "bundle",
  "--module", "Main",
  "--platform", "browser",
  "--bundle-type", "app",
  "--outfile", join(dist, "forge.js"),
  "--minify",
  "--strict",
]);

for (const entry of readdirSync(join(root, "public"))) {
  if (entry !== "forge.js") cpSync(join(root, "public", entry), join(dist, entry), { recursive: true });
}
cpSync(orbitalAssets, join(dist, "orbital"), { recursive: true });

for (const file of ["index.html", "forge.js", "forge.css", "orbital/hydrogen.css"]) {
  const target = join(dist, file);
  if (!existsSync(target) || statSync(target).size === 0) throw new Error(`orbital-forge: missing ${file}`);
}

if (process.argv.includes("--vercel")) {
  const apiBase = process.env.ORBITAL_FORGE_API_BASE
    ?? "https://git.s4.gl/orbital-forge/api/forge/v1";
  const parsedApiBase = new URL(apiBase);
  if (parsedApiBase.protocol !== "https:") {
    throw new Error("orbital-forge: the deployed API base must use HTTPS");
  }
  const indexPath = join(dist, "index.html");
  const index = readFileSync(indexPath, "utf8");
  writeFileSync(
    indexPath,
    index.replace(
      '<meta name="orbital-forge-api" content="/api/forge/v1">',
      `<meta name="orbital-forge-api" content="${parsedApiBase.href.replace(/\/$/, "")}">`,
    ),
    "utf8",
  );
  const output = join(root, ".vercel", "output");
  rmSync(output, { recursive: true, force: true });
  mkdirSync(join(output, "static"), { recursive: true });
  for (const entry of readdirSync(dist)) cpSync(join(dist, entry), join(output, "static", entry), { recursive: true });
  const config = { version: 3 };
  writeFileSync(join(output, "config.json"), `${JSON.stringify(config, null, 2)}\n`, "utf8");
  console.log(`orbital-forge: Vercel output -> ${output}`);
}

console.log(`orbital-forge: PureScript app -> ${dist}`);
