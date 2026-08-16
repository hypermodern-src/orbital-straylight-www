import { mkdirSync, writeFileSync } from "node:fs";

export const mkdirp = (directory) => () => {
  mkdirSync(directory, { recursive: true });
};

export const outputDirectory = () => {
  const output = process.argv[1];
  if (!output) throw new Error("orbital-ssg: missing output directory");
  return output;
};

export const writeTextFile = (path) => (contents) => () => {
  writeFileSync(path, contents, "utf8");
};
