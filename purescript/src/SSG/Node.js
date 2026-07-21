// FFI for SSG.Node — node only; never reached by the browser bundle.
import { mkdirSync, writeFileSync } from "node:fs";

export const argv = () => process.argv;

export const mkdirp = (dir) => () => {
  mkdirSync(dir, { recursive: true });
};

export const writeTextFile = (path) => (contents) => () => {
  writeFileSync(path, contents, "utf8");
};
