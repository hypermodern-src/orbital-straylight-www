// themes-states.mjs — the per-component state driver shared by every interactive gate
// (themes-open-dom.mjs DOM oracle, themes-a11y.mjs a11y oracle). ONE source of truth for
// "how to drive component <id> into state <state>", keyed off the upstream class/role
// selectors the Halogen port must reproduce — so the DOM-structure gate, the a11y-tree
// gate, and (separately) the APG keyboard gate can never drift on what "open" means.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";

// A tiny static file server (ephemeral port so parallel runs never collide).
export async function serve(dir) {
  const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
  const srv = createServer(async (q, s) => {
    let p = q.url.split("?")[0]; if (p === "/") p = "/index.html";
    try { const b = await readFile(join(dir, p)); s.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream"); s.setHeader("Cache-Control", "no-store"); s.end(b); }
    catch { s.statusCode = 404; s.end("nf"); }
  }).listen(0);
  await new Promise((r) => srv.once("listening", r));
  return { port: srv.address().port, close: () => srv.close() };
}

export const root = (pg) => pg.locator("#root");
export const triggerButton = (pg) => root(pg).getByRole("button").first();
export const settle = (pg) => pg.waitForTimeout(300); // let Popper position + presence flush

const openMenu = async (pg, click) => { await click(); await pg.locator('[role="menu"]').first().waitFor(); };

// id → { state → (pg) => drive into that state }. `open` is the canonical "shown" state
// every overlay has; richer states (item highlighted, option selected) extend per component.
export const STATES = {
  dialog: {
    open: async (pg) => { await triggerButton(pg).click(); await pg.getByRole("dialog").waitFor(); },
  },
  alertdialog: {
    open: async (pg) => { await triggerButton(pg).click(); await pg.getByRole("alertdialog").waitFor(); },
  },
  popover: {
    open: async (pg) => { await triggerButton(pg).click(); await pg.locator(".rt-PopoverContent").waitFor(); },
  },
  tooltip: {
    open: async (pg) => { await triggerButton(pg).hover(); await pg.getByRole("tooltip").waitFor(); },
  },
  hovercard: {
    open: async (pg) => { await root(pg).getByRole("link").first().hover(); await pg.locator(".rt-HoverCardContent").waitFor(); },
  },
  dropdownmenu: {
    open: async (pg) => openMenu(pg, () => triggerButton(pg).click()),
    item2: async (pg) => {
      await openMenu(pg, () => triggerButton(pg).click());
      await pg.keyboard.press("ArrowDown");
      await pg.keyboard.press("ArrowDown");
    },
  },
  contextmenu: {
    open: async (pg) => openMenu(pg, () => pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" })),
  },
  select: {
    open: async (pg) => { await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); },
  },
};
