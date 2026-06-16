// open-shoot.mjs <dist> <id> <state> <out> — drive an interactive Themes golden (?c=<id>)
// into <state> via the shared state driver, then screenshot (animations frozen). The
// visual target/comparison for the open-state Themes preset work (STR-338).
import { serve, STATES, settle } from "./themes-states.mjs";
import { chromium } from "@playwright/test";

const [DIR, ID, STATE = "open", OUT] = process.argv.slice(2);
const { port: PORT, close: closeSrv } = await serve(DIR);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1000, height: 760 }, deviceScaleFactor: 2 });
await pg.goto(`http://127.0.0.1:${PORT}/?c=${ID}`);
await pg.waitForTimeout(250);
const step = STATES[ID] && STATES[ID][STATE];
if (step) { await step(pg); await settle(pg); }
await pg.screenshot({ path: OUT, animations: "disabled" });
await b.close(); closeSrv();
console.log(OUT);
