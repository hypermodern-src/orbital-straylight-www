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
  throw new Error("ponce-speedway: missing local tools; run npm ci first");
}

rmSync(build, { recursive: true, force: true });
rmSync(dist, { recursive: true, force: true });
mkdirSync(build, { recursive: true });
mkdirSync(dist, { recursive: true });

run(spago, [
  "bundle",
  "--module", "Ponce.SSG",
  "--platform", "node",
  "--bundle-type", "module",
  "--outfile", join(build, "ponce-ssg.mjs"),
  "--strict",
]);

run(process.execPath, [
  "-e",
  "import('./.build/ponce-ssg.mjs').then((m) => m.main())",
  dist,
  join(root, "content", "site.json"),
]);

for (const entry of readdirSync(join(root, "static"))) {
  cpSync(join(root, "static", entry), join(dist, entry), { recursive: true });
}

const requiredRoutes = [
  "index.html",
  "circuit/index.html",
  "events/index.html",
  "fanclub/index.html",
  "karting/index.html",
  "sponsors/index.html",
  "suites/index.html",
  "es/index.html",
  "es/circuito/index.html",
  "es/eventos/index.html",
  "es/fanaticos/index.html",
  "es/karting/index.html",
  "es/patrocinadores/index.html",
  "es/suites/index.html",
];

for (const route of requiredRoutes) {
  const output = join(dist, route);
  if (!existsSync(output) || statSync(output).size === 0) {
    throw new Error(`ponce-speedway: generator did not produce ${route}`);
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
  console.log(`ponce-speedway: Vercel output -> ${vercelOutput}`);
}

console.log(`ponce-speedway: ${requiredRoutes.length} Hydrogen routes -> ${dist}`);
