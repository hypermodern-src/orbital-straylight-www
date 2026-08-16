// themes-shoot-state.mjs <dist> <id> <state> <out> — screenshot a component DRIVEN into
// its open state, using the SAME state driver (themes-states.mjs) as the DOM/a11y oracles.
// This is what makes the port↔golden screenshot honest: the golden app renders the demo
// CLOSED (its open-state is a driven state, not a navigation), so to compare open-vs-open
// we drive both the same way. The port renders defaultOpen=true, but the driver is
// idempotent (clicking an already-open trigger is a no-op), so one script serves both.
import { chromium } from "@playwright/test";
import { serve, STATES, settle } from "./themes-states.mjs";

const [DIR, ID, STATE, OUT] = process.argv.slice(2);
const drive = STATES[ID]?.[STATE];
if (!drive) { console.error(`no driver for ${ID}:${STATE}`); process.exit(1); }

const { port, close } = await serve(DIR);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 820, height: 640 }, deviceScaleFactor: 2 });
await pg.goto(`http://127.0.0.1:${port}/?c=${ID}`);
await pg.waitForTimeout(200);
await drive(pg);
await settle(pg);
await pg.screenshot({ path: OUT, fullPage: true, animations: "disabled" });
await b.close(); close();
console.log(OUT);
