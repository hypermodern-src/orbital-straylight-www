/* Deploy-time build: copy the static site into dist/ and minify CSS/JS there.
   Source files, including the vendored halogen-orbital design system, stay
   untouched in git; minification happens only in the deploy artifact. */
import { cpSync, mkdirSync, rmSync, readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';
import { transformSync } from 'esbuild';

const OUT = 'dist';
const INCLUDE = [
  'index.html', 'cache.html', 'build.html', 'pricing.html', 'verification.html',
  'about.html', 'thanks.html', 'waitlist.js', 'waitlist.css', 'fonts.css',
  'favicon.svg', 'robots.txt', 'sitemap.xml', 'fonts', 'halogen-orbital'
];

rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT);
for (const item of INCLUDE) cpSync(item, join(OUT, item), { recursive: true });

function walk(dir, files = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, files);
    else files.push(p);
  }
  return files;
}

let saved = 0;
for (const file of walk(OUT)) {
  const ext = extname(file);
  if (ext !== '.css' && ext !== '.js') continue;
  const src = readFileSync(file, 'utf8');
  const { code } = transformSync(src, { loader: ext === '.css' ? 'css' : 'js', minify: true });
  writeFileSync(file, code);
  saved += src.length - code.length;
}
console.log(`build: dist ready, ${(saved / 1024).toFixed(1)}KB trimmed from CSS/JS`);
