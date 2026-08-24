import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { transformSync } from "esbuild";

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
  throw new Error("camp-caribe: missing local tools; run npm ci first");
}

rmSync(build, { recursive: true, force: true });
rmSync(dist, { recursive: true, force: true });
mkdirSync(build, { recursive: true });
mkdirSync(dist, { recursive: true });

run(spago, [
  "bundle",
  "--module", "Camp.SSG",
  "--platform", "node",
  "--bundle-type", "module",
  "--outfile", join(build, "camp-caribe-ssg.mjs"),
  "--strict",
]);

run(process.execPath, [
  "-e",
  "import('./.build/camp-caribe-ssg.mjs').then((m) => m.main())",
  dist,
  join(root, "content", "site.json"),
]);

for (const entry of readdirSync(join(root, "static"))) {
  cpSync(join(root, "static", entry), join(dist, entry), { recursive: true });
}

for (const [file, loader] of [["style.css", "css"], ["site.js", "js"]]) {
  const output = join(dist, file);
  const transformed = transformSync(readFileSync(output, "utf8"), {
    loader,
    minify: true,
    target: "es2020",
  });
  writeFileSync(output, transformed.code);
}

const requiredRoutes = [
  "index.html",
  "venue/index.html",
  "missions/index.html",
  "gallery/index.html",
  "contact/index.html",
  "es/index.html",
  "es/recinto/index.html",
  "es/usos/index.html",
  "es/galeria/index.html",
  "es/contacto/index.html",
];

for (const route of requiredRoutes) {
  const output = join(dist, route);
  if (!existsSync(output) || statSync(output).size === 0) {
    throw new Error(`camp-caribe: generator did not produce ${route}`);
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
  console.log(`camp-caribe: Vercel output -> ${vercelOutput}`);
}

console.log(`camp-caribe: ${requiredRoutes.length} Hydrogen routes -> ${dist}`);
