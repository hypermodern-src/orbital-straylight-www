import { mkdirSync, readFileSync, writeFileSync } from "node:fs";

export const contentPath = () => {
  const value = process.argv[2];
  if (!value) throw new Error("ponce-speedway: missing content path");
  return value;
};

export const mkdirp = (directory) => () => {
  mkdirSync(directory, { recursive: true });
};

export const outputDirectory = () => {
  const value = process.argv[1];
  if (!value) throw new Error("ponce-speedway: missing output directory");
  return value;
};

export const readJsonFile = (file) => () =>
  JSON.parse(readFileSync(file, "utf8"));

export const writeTextFile = (file) => (contents) => () => {
  writeFileSync(file, contents, "utf8");
};
