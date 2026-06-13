// FFI for Reinit.SSG — node-only, used at SSG (prerender) time by the purs_site
// rule. Never reached in the browser bundle (Main does not import these).
import * as fs from "node:fs";

// process.argv[1] under `node -e "<script>" <shell>` is the shell HTML path.
export const argv1 = () => process.argv[1];

export const readFileUtf8 = (path) => () => fs.readFileSync(path, "utf8");
