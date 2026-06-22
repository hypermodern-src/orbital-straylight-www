// themes-apg.mjs <dist> [<id> …] — WAI-ARIA APG keyboard-conformance gate (STR-332).
//
// Encodes the WAI-ARIA Authoring Practices key→behavior tables as executable checks
// and runs them against a dist. Validated against the REAL @radix-ui/themes golden
// (so the expectations are spec-grounded, not self-invented — the same non-circular
// discipline as the DOM oracle); then run unchanged against //examples/themes-port:app
// to prove the Hydrogen.Radix behavior layer (FocusScope / RovingFocus / DismissableLayer)
// matches the spec end-to-end. Each check cites the APG pattern it encodes.
//
// A check fails with the exact key + expected vs actual focus/selection/open-state.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";
import { chromium } from "@playwright/test";

const [DIR, ...ONLY] = process.argv.slice(2);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css" };
const srv = createServer(async (q, s) => {
  let p = q.url.split("?")[0]; if (p === "/") p = "/index.html";
  try { const b = await readFile(join(DIR, p)); s.setHeader("Content-Type", MIME[extname(p)] ?? "application/octet-stream"); s.setHeader("Cache-Control", "no-store"); s.end(b); }
  catch { s.statusCode = 404; s.end("nf"); }
}).listen(0);
await new Promise((r) => srv.once("listening", r));
const PORT = srv.address().port;

// ── DOM probes (run in-page) ─────────────────────────────────────────────────
const activeWithin = (pg, sel) => pg.evaluate((s) => { const c = document.querySelector(s); return !!(c && document.activeElement && c.contains(document.activeElement)); }, sel);
const activeIs = (pg, sel) => pg.evaluate((s) => document.activeElement === document.querySelector(s), sel);
const highlightedText = (pg) => pg.evaluate(() => { const e = document.querySelector("[data-highlighted]"); return e ? (e.textContent || "").trim().slice(0, 40) : null; });
const visible = (pg, sel) => pg.locator(sel).first().isVisible().catch(() => false);
const ok = (cond, msg) => { if (!cond) throw new Error(msg); };
// menu/listbox item text carries the shortcut suffix ("Edit⌘ E") — match by label prefix.
// Poll: roving focus settles a frame or two after the keypress, so don't assert on a fixed delay.
const hlStarts = async (pg, label) => {
  let t = null;
  for (let i = 0; i < 20; i++) { t = await highlightedText(pg); if (t?.startsWith(label)) return; await pg.waitForTimeout(50); }
  ok(false, `expected "${label}…" highlighted (got ${t})`);
};

const triggerBtn = (pg) => pg.locator("#root").getByRole("button").first();
const selectValue = (pg) => pg.locator(".rt-SelectTrigger").textContent();

// Roving-tabindex + selection probes for the stateful non-overlay patterns.
// `attr` reads a DOM attribute off the Nth element matching `sel` (selection-follows-focus
// asserts aria-checked/data-state; roving tabindex asserts tabindex=0 on exactly one item).
const attrOf = (pg, sel, n, name) => pg.evaluate(({ s, i, a }) => {
  const el = document.querySelectorAll(s)[i];
  return el ? el.getAttribute(a) : null;
}, { s: sel, i: n, a: name });
// document.activeElement is the Nth element matching sel.
const activeIsNth = (pg, sel, n) => pg.evaluate(({ s, i }) => document.activeElement === document.querySelectorAll(s)[i], { s: sel, i: n });
// count of elements matching sel whose tabindex === "0" (roving: must be exactly one).
const tabbableCount = (pg, sel) => pg.evaluate((s) => [...document.querySelectorAll(s)].filter((e) => e.getAttribute("tabindex") === "0").length, sel);
// focus the first element matching sel via the keyboard-independent DOM API.
const focusFirst = (pg, sel) => pg.evaluate((s) => { const e = document.querySelector(s); if (e) e.focus(); }, sel);
// press a key then let RovingFocus / activation effects flush (one keypress at a time).
const press = async (pg, key) => { await pg.keyboard.press(key); await pg.waitForTimeout(80); };
// poll until attrOf(sel,n,name) === want (roving/selection settle a frame or two after a key).
const attrEq = async (pg, sel, n, name, want, msg) => {
  for (let i = 0; i < 25; i++) { if ((await attrOf(pg, sel, n, name)) === want) return; await pg.waitForTimeout(40); }
  ok(false, `${msg} (expected ${name}=${want}, got ${await attrOf(pg, sel, n, name)})`);
};

// ── the conformance checks, grouped by APG pattern ───────────────────────────
const CHECKS = [
  // Dialog (Modal) — https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
  { id: "dialog", apg: "dialog-modal", name: "open moves focus into the dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(150);
    ok(await activeWithin(pg, '[role="dialog"]'), "focus did not move into the dialog on open");
  }},
  { id: "dialog", apg: "dialog-modal", name: "Tab is trapped within the dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(150);
    for (let i = 0; i < 6; i++) await pg.keyboard.press("Tab");
    ok(await activeWithin(pg, '[role="dialog"]'), "Tab escaped the dialog (focus trap broken)");
  }},
  { id: "dialog", apg: "dialog-modal", name: "Escape closes and returns focus to the trigger", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(150);
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(200);
    ok(!(await visible(pg, '[role="dialog"]')), "Escape did not close the dialog");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Escape");
  }},

  // Accordion — https://www.w3.org/WAI/ARIA/apg/patterns/accordion/
  // Vertical accordion: ArrowDown/ArrowUp move focus between TRIGGERS, relative to the
  // CURRENTLY FOCUSED trigger (accordion.tsx:235-240 derives triggerIndex from event.target,
  // NOT the open/first item), wrapping; the navigable collection EXCLUDES disabled triggers
  // (accordion.tsx:236 filter(!disabled)) so arrows SKIP OVER them. Triggers carry aria-expanded.
  { id: "accordion", state: "open", apg: "accordion", name: "ArrowDown moves relative to the FOCUSED trigger (nav origin = event.target)", run: async (pg) => {
    const t = (n) => pg.locator('#root button[aria-expanded]').nth(n);
    await t(0).waitFor();
    await t(1).focus(); // focus the MIDDLE trigger
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 1), "could not focus the middle trigger");
    await press(pg, "ArrowDown");
    // origin must be the focused (#2, idx 1) → next is #3 (idx 2); the old bug computed
    // origin from the open/first item (idx 0) and would land on #2 (idx 1, no move).
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 2), "ArrowDown did not move relative to the focused trigger (landed off #3)");
  }},
  { id: "accordion", state: "open", apg: "accordion", name: "Home/End focus the first/last trigger", run: async (pg) => {
    await pg.locator('#root button[aria-expanded]').first().waitFor();
    await pg.locator('#root button[aria-expanded]').nth(1).focus();
    await press(pg, "End");
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 2), "End did not focus the last trigger");
    await press(pg, "Home");
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 0), "Home did not focus the first trigger");
  }},
  { id: "accordion", state: "disabled", apg: "accordion", name: "ArrowDown SKIPS OVER a disabled trigger to the next enabled one", run: async (pg) => {
    const all = pg.locator('#root button[aria-expanded]');
    await all.first().waitFor();
    ok((await all.count()) === 3, "expected 3 triggers");
    ok((await attrOf(pg, '#root button[aria-expanded]', 1, "disabled")) !== null, "the middle trigger must be disabled in this state");
    await all.nth(0).focus(); // focus #1 (enabled)
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 0), "could not focus the first trigger");
    await press(pg, "ArrowDown");
    // #2 is disabled → it is OUT of the collection, so ArrowDown lands on #3 (the next
    // ENABLED trigger), never on the disabled #2.
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 2), "ArrowDown did not skip the disabled middle trigger to #3");
  }},

  // Menu Button + Menu — https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/
  { id: "dropdownmenu", apg: "menu-button", name: "ArrowDown on the trigger opens and focuses the first item", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    ok(await activeWithin(pg, '[role="menu"]'), "menu did not receive focus");
    await hlStarts(pg, "Edit");
  }},
  // Keyboard-opened (ArrowDown opens + highlights first) — then rove from a known state.
  { id: "dropdownmenu", apg: "menu", name: "ArrowDown roves to the next item", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor();
    await hlStarts(pg, "Edit");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Duplicate");
  }},
  { id: "dropdownmenu", apg: "menu", name: "End highlights the last item, Home the first", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor();
    await hlStarts(pg, "Edit");
    await pg.keyboard.press("End"); await hlStarts(pg, "Delete");
    await pg.keyboard.press("Home"); await hlStarts(pg, "Edit");
  }},
  { id: "dropdownmenu", apg: "menu", name: "Escape closes and returns focus to the trigger", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "Escape did not close the menu");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Escape");
  }},
  // Disabled item is SKIPPED by roving navigation (menu.tsx:540 filter(!disabled), :720
  // focusable={!disabled}); it renders data-disabled + tabindex=-1 but is never highlighted
  // and ArrowDown jumps OVER it to the next enabled item. (?s=disabled disables Duplicate.)
  { id: "dropdownmenu", state: "disabled", apg: "menu", name: "ArrowDown SKIPS a disabled item to the next enabled one", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "Edit");
    // the disabled item carries data-disabled and is NOT in the roving order (tabindex -1).
    ok((await pg.evaluate(() => { const e = [...document.querySelectorAll('[role="menuitem"]')].find((x) => (x.textContent || "").startsWith("Duplicate")); return e && e.hasAttribute("data-disabled") && e.getAttribute("tabindex") === "-1"; })), "disabled item must be data-disabled + tabindex=-1");
    // ArrowDown from Edit must SKIP the disabled Duplicate and land on Archive.
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Archive");
  }},
  // Submenu — ArrowRight on a focused SubTrigger OPENS the nested SubContent (a 2nd role=menu)
  // and focuses its first item; ArrowLeft / Escape close it back to the SubTrigger. Validated on
  // --golden (real radix does the same) so the key→behavior table is non-circular.
  { id: "dropdownmenu", state: "submenu", apg: "menu", name: "ArrowRight opens the submenu; ArrowLeft closes it", run: async (pg) => {
    // keyboard-open (ArrowDown on the trigger) → menu open, first item (Edit) highlighted.
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').first().waitFor();
    await hlStarts(pg, "Edit");
    // rove Edit → Duplicate → Archive → More (the SubTrigger); hlStarts waits each settle.
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Duplicate");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Archive");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "More");
    // ArrowRight opens the submenu (a 2nd role=menu); SubTrigger flips to data-state=open.
    await pg.keyboard.press("ArrowRight");
    await pg.waitForFunction(() => document.querySelectorAll('[role="menu"]').length >= 2, null, { timeout: 3000 });
    ok((await pg.evaluate(() => { const t = document.querySelector('[role="menuitem"][aria-haspopup="menu"]'); return t && t.getAttribute("data-state") === "open" && t.getAttribute("aria-expanded") === "true"; })),
      "ArrowRight must open the submenu (SubTrigger data-state=open, aria-expanded=true)");
    // ArrowLeft closes the sub and returns to the SubTrigger.
    await pg.keyboard.press("ArrowLeft");
    await pg.waitForFunction(() => document.querySelectorAll('[role="menu"]').length === 1, null, { timeout: 3000 });
    ok((await pg.evaluate(() => { const t = document.querySelector('[role="menuitem"][aria-haspopup="menu"]'); return t && t.getAttribute("data-state") === "closed"; })),
      "ArrowLeft must close the submenu (SubTrigger data-state=closed)");
  }},

  // Menubar — https://www.w3.org/WAI/ARIA/apg/patterns/menubar/
  // The trigger bar is a horizontal RovingFocus of role=menuitem buttons; each opens a
  // DropdownMenu-style role=menu. APG menubar keyboard table: on the BAR ArrowRight→next
  // trigger (loop), ArrowLeft→prev, Home→first, End→last; on a CLOSED trigger ArrowDown
  // opens + focuses the first item; INSIDE a menu ArrowDown/Up rove (loop) and
  // ArrowRight/ArrowLeft close it + open the adjacent trigger's menu; Escape closes + restores
  // focus to the trigger. The bare menubar has 3 triggers (File/Edit/View); File's menu has
  // New Tab / New Window / sep / Print. Keyed off role/data-highlighted only → same on the port.
  { id: "menubar", apg: "menubar", name: "ArrowRight/ArrowLeft rove between triggers along the bar (loop)", run: async (pg) => {
    const t = (n) => pg.locator('#root [role="menuitem"]').nth(n);
    await t(0).focus();
    ok(await activeIs(pg, '#root [role="menuitem"]'), "could not focus the first trigger");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, '#root [role="menuitem"]', 1), "ArrowRight did not move to the next trigger");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, '#root [role="menuitem"]', 0), "ArrowLeft did not move back to the previous trigger");
  }},
  { id: "menubar", apg: "menubar", name: "Home focuses the first trigger, End the last", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().waitFor();
    await pg.locator('#root [role="menuitem"]').first().focus();
    await press(pg, "End");
    ok(await activeIsNth(pg, '#root [role="menuitem"]', 2), "End did not focus the last trigger");
    await press(pg, "Home");
    ok(await activeIsNth(pg, '#root [role="menuitem"]', 0), "Home did not focus the first trigger");
  }},
  // Enter/Space on a CLOSED trigger open the menu AND highlight the first item (menubar.tsx:
  // 260-269 onMenuToggle + wasKeyboardTriggerOpenRef=true → first item focused, like ArrowDown).
  { id: "menubar", apg: "menubar", name: "Enter on a trigger opens the menu and highlights the first item", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("Enter");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    ok(await activeWithin(pg, '[role="menu"]'), "Enter did not move focus into the opened menu");
    await hlStarts(pg, "New Tab");
  }},
  { id: "menubar", apg: "menubar", name: "typeahead: a letter focuses the next matching item in the open menu, repeats cycle", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("Enter");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(150);
    await hlStarts(pg, "New Tab"); // items: New Tab, New Window, Print
    await pg.keyboard.press("n"); await hlStarts(pg, "New Window");
    await pg.keyboard.press("n"); await hlStarts(pg, "New Tab"); // repeated char cycles the n-items
    await pg.waitForTimeout(1100);
    await pg.keyboard.press("p"); await hlStarts(pg, "Print"); // fresh search
  }},
  { id: "menubar", apg: "menubar", name: "Tab is prevented (focus stays in the open menu)", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("Enter");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "New Tab");
    await pg.keyboard.press("Tab"); await pg.waitForTimeout(100);
    ok(await activeWithin(pg, '[role="menu"]'), "Tab escaped the open menu");
  }},
  { id: "menubar", apg: "menubar", name: "PageDown focuses the last menu item, PageUp the first", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("Enter");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "New Tab");
    await pg.keyboard.press("PageDown"); await hlStarts(pg, "Print");
    await pg.keyboard.press("PageUp"); await hlStarts(pg, "New Tab");
  }},
  { id: "menubar", apg: "menubar", name: "loop off (default): ArrowDown on the last menu item does NOT wrap", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("Enter");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "New Tab"); // File: New Tab, New Window, Print
    await pg.keyboard.press("End"); await hlStarts(pg, "Print");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Print"); // last item: no wrap
  }},
  { id: "menubar", apg: "menubar", name: "Space on a trigger opens the menu and highlights the first item", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("Space");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    ok(await activeWithin(pg, '[role="menu"]'), "Space did not move focus into the opened menu");
    await hlStarts(pg, "New Tab");
  }},
  { id: "menubar", apg: "menubar", name: "ArrowDown on a trigger opens the menu and focuses the first item", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    ok(await activeWithin(pg, '[role="menu"]'), "ArrowDown did not move focus into the opened menu");
    await hlStarts(pg, "New Tab");
  }},
  { id: "menubar", apg: "menu", name: "inside a menu ArrowDown/Up rove the items", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor();
    await hlStarts(pg, "New Tab");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "New Window");
    await pg.keyboard.press("ArrowUp"); await hlStarts(pg, "New Tab");
  }},
  { id: "menubar", apg: "menubar", name: "ArrowRight inside an open menu opens the adjacent menu", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    // the open menu is File's (aria-labelledby → File). ArrowRight closes it and opens Edit's.
    await pg.keyboard.press("ArrowRight"); await pg.waitForTimeout(180);
    const openLabel = await pg.evaluate(() => { const m = document.querySelector('[role="menu"]'); const l = m && document.getElementById(m.getAttribute("aria-labelledby")); return l ? l.textContent.trim() : null; });
    ok(openLabel === "Edit", `ArrowRight did not open the adjacent (Edit) menu (open menu is ${openLabel})`);
    ok(await activeWithin(pg, '[role="menu"]'), "focus did not move into the adjacent menu");
  }},
  { id: "menubar", apg: "menubar", name: "Escape closes the menu and returns focus to its trigger", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "Escape did not close the menu");
    ok(await activeIsNth(pg, '#root [role="menuitem"]', 0), "focus did not return to the trigger after Escape");
  }},

  // NavigationMenu — https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/ (navigation variant).
  // The trigger bar is a HORIZONTAL FocusGroup of role=button triggers + role=link items;
  // ArrowLeft/ArrowRight move between FocusGroup items but DO NOT LOOP (slice-from-current,
  // unlike Tabs/Menu). With its content OPEN, ArrowDown (horizontal) on the trigger moves focus
  // INTO the content (first tabbable link); Escape closes + restores focus to the trigger. The
  // `open` story renders OPEN at first paint via defaultValue="one" (NO open-delay timer on the
  // capture path). Keyed off role/aria-expanded/data-state only → same on the port. Two items
  // (Item One open / Item Two); Item One's content has two links.
  { id: "navigationmenu", state: "open", apg: "disclosure", name: "ArrowRight/ArrowLeft rove between triggers (NON-looping)", run: async (pg) => {
    await pg.locator('#root button[aria-expanded]').first().waitFor();
    await focusFirst(pg, '#root button[aria-expanded]');
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 0), "could not focus the first trigger");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 1), "ArrowRight did not move to the next trigger");
    // NON-looping: a second ArrowRight at the last item stays put (no wrap to the first).
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 1), "ArrowRight wrapped (NavigationMenu FocusGroup must NOT loop)");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 0), "ArrowLeft did not move back to the previous trigger");
  }},
  { id: "navigationmenu", state: "open", apg: "disclosure", name: "ArrowDown on the open trigger moves focus into the content", run: async (pg) => {
    await pg.locator('#root button[aria-expanded="true"]').first().waitFor();
    await focusFirst(pg, '#root button[aria-expanded="true"]');
    ok(await activeIs(pg, '#root button[aria-expanded="true"]'), "could not focus the open trigger");
    await press(pg, "ArrowDown");
    ok(await activeWithin(pg, '[aria-labelledby]'), "ArrowDown did not move focus into the open content");
  }},
  { id: "navigationmenu", state: "open", apg: "disclosure", name: "Escape closes the content and returns focus to the trigger", run: async (pg) => {
    await pg.locator('#root button[aria-expanded="true"]').first().waitFor();
    await focusFirst(pg, '#root button[aria-expanded="true"]');
    await press(pg, "ArrowDown"); // focus into content first (Escape fires from inside)
    ok(await activeWithin(pg, '[aria-labelledby]'), "did not move focus into the content");
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await pg.locator('#root button[aria-expanded="true"]').count()), "Escape did not close the menu (a trigger is still expanded)");
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 0), "focus did not return to the trigger after Escape");
  }},

  // Listbox (Select) — https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ (select-only)
  { id: "select", apg: "listbox", name: "open highlights the selected option", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "Apple");
  }},
  { id: "select", apg: "listbox", name: "ArrowDown roves to the next option", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Orange");
  }},
  // ?s=disabled disables the middle option (Orange); ArrowDown must skip it (select.tsx
  // focusable={!disabled}). Validated on the golden first.
  { id: "select", apg: "listbox", state: "disabled", name: "ArrowDown SKIPS a disabled option to the next enabled one", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(150);
    await hlStarts(pg, "Apple");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Grape");
  }},
  { id: "select", apg: "listbox", name: "loop off (default): ArrowDown on the last option does NOT wrap", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(150);
    await hlStarts(pg, "Apple");
    await pg.keyboard.press("End"); await hlStarts(pg, "Grape");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Grape");
  }},
  { id: "select", apg: "listbox", name: "typeahead: a letter focuses the matching option (idle reset)", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(150);
    await hlStarts(pg, "Apple"); // options: Apple, Orange, Grape
    await pg.keyboard.press("g"); await hlStarts(pg, "Grape");
    await pg.waitForTimeout(1100); await pg.keyboard.press("o"); await hlStarts(pg, "Orange"); // fresh search after reset
    await pg.waitForTimeout(1100); await pg.keyboard.press("a"); await hlStarts(pg, "Apple");
  }},
  // On open, DOM focus lands on the SELECTED option (upstream focusSelectedItem,
  // select.tsx:683-714 focusFirst([selectedItem, content])), not the content/listbox —
  // so ArrowUp/Down originate from it and the SR announces it. (Validated on --golden first.)
  { id: "select", apg: "listbox", name: "open moves focus to the SELECTED option", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(150);
    ok(await activeIs(pg, '[role="option"][aria-selected="true"]'), "open did not focus the selected option");
    ok((await pg.evaluate(() => (document.activeElement.textContent || "").trim())) === "Apple", "the focused option must be the selected one (Apple)");
  }},
  { id: "select", apg: "listbox", name: "Enter selects the highlighted option and closes", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("ArrowDown"); await pg.keyboard.press("Enter"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="listbox"]')), "Enter did not close the listbox");
    ok((await selectValue(pg))?.includes("Orange"), `trigger should now show Orange (got ${await selectValue(pg)})`);
  }},
  { id: "select", apg: "listbox", name: "Escape closes without changing the value", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("ArrowDown"); await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="listbox"]')), "Escape did not close the listbox");
    ok((await selectValue(pg))?.includes("Apple"), `value should remain Apple (got ${await selectValue(pg)})`);
  }},

  // Tooltip — https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/
  { id: "tooltip", apg: "tooltip", name: "focus shows the tooltip", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.getByRole("tooltip").waitFor({ timeout: 3000 });
    ok(await visible(pg, '[role="tooltip"], .rt-TooltipContent'), "tooltip did not show on focus");
  }},
  { id: "tooltip", apg: "tooltip", name: "Escape hides the tooltip", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.getByRole("tooltip").waitFor({ timeout: 3000 });
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="tooltip"]')), "Escape did not hide the tooltip");
  }},
  // aria-describedby is set on the trigger ONLY while open (upstream tooltip.tsx:290
  // `context.open ? context.contentId : undefined`). Closed ⇒ the attribute is ABSENT;
  // open ⇒ it points at the role=tooltip content's id. (Validated on --golden first.)
  { id: "tooltip", apg: "tooltip", name: "aria-describedby is absent when closed, present (→ the tooltip) when open", run: async (pg) => {
    await triggerBtn(pg).waitFor();
    ok((await attrOf(pg, "#root button", 0, "aria-describedby")) === null,
      "trigger must have NO aria-describedby while the tooltip is closed");
    await triggerBtn(pg).focus(); await pg.getByRole("tooltip").waitFor({ timeout: 3000 }); await pg.waitForTimeout(120);
    const db = await attrOf(pg, "#root button", 0, "aria-describedby");
    ok(db !== null && db !== "", "trigger must gain aria-describedby when the tooltip opens");
    const linked = await pg.evaluate((id) => { const e = document.getElementById(id); return !!(e && e.getAttribute("role") === "tooltip"); }, db);
    ok(linked, `aria-describedby (${db}) must reference the role=tooltip content`);
  }},
  // Hover DEFERS the open: radix waits delayDuration (DEFAULT_DELAY_DURATION=700ms) before
  // showing on pointer, so a glance that brushes past the trigger never flashes the tooltip.
  // Assert it is STILL closed shortly after pointer-enter, then opens once the delay elapses.
  // Non-circular: validated on --golden (real radix delays identically); the port realises it
  // via Tooltip's delayMs Input + a cancellable setTimeout (cleared on early pointer-leave).
  { id: "tooltip", apg: "tooltip", name: "hover defers the open by the delay (no instant flash)", run: async (pg) => {
    await triggerBtn(pg).waitFor();
    await triggerBtn(pg).hover();
    await pg.waitForTimeout(80);
    ok(!(await visible(pg, '[role="tooltip"]')), "tooltip flashed open before the hover delay elapsed");
    await pg.getByRole("tooltip").waitFor({ timeout: 3000 });
    ok(await visible(pg, '[role="tooltip"], .rt-TooltipContent'), "tooltip never opened after the hover delay");
  }},
  // A pointer-leave DURING the delay window CANCELS the pending open (clearTimeout) — the
  // tooltip must never appear for a transient hover. Hover, leave before the delay, then wait
  // past it and assert still-closed. Non-circular (real radix cancels the same way).
  { id: "tooltip", apg: "tooltip", name: "leaving during the delay cancels the pending open", run: async (pg) => {
    await triggerBtn(pg).waitFor();
    await triggerBtn(pg).hover();
    await pg.waitForTimeout(80);
    await pg.mouse.move(0, 0);                 // leave the trigger before the delay elapses
    await pg.waitForTimeout(900);              // wait well past DEFAULT_DELAY_DURATION
    ok(!(await visible(pg, '[role="tooltip"]')), "a cancelled hover still opened the tooltip");
  }},

  // Radio Group — https://www.w3.org/WAI/ARIA/apg/patterns/radio/
  // Keyboard table: Tab moves focus into the group, onto the checked radio (or first if none
  // checked). Down/Right Arrow → focus & CHECK the next radio (selection-follows-focus),
  // wrapping to the first at the end. Up/Left Arrow → focus & check the previous, wrapping to
  // the last. Only one radio is in the Tab sequence (roving tabindex). Seed: defaultValue="1"
  // so radio[value=1] is checked (tabindex 0) and radio[value=2] is unchecked (tabindex -1).
  { id: "radiogroup", state: "checked", apg: "radio", name: "Tab moves focus onto the checked radio (roving tabindex)", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab");
    ok(await activeIsNth(pg, '[role="radio"]', 0), "Tab did not land focus on the checked radio");
    // RovingFocus settles tabindex once focus enters: exactly one radio (the focused/checked) is tabbable.
    ok((await tabbableCount(pg, '[role="radio"]')) === 1, "exactly one radio must be tabbable after entry (roving tabindex)");
    ok((await attrOf(pg, '[role="radio"]', 0, "tabindex")) === "0", "the checked radio must be the tabbable one");
  }},
  { id: "radiogroup", state: "checked", apg: "radio", name: "ArrowDown moves to next radio AND checks it (selection-follows-focus)", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab");
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, '[role="radio"]', 1), "ArrowDown did not move focus to the next radio");
    await attrEq(pg, '[role="radio"]', 1, "data-state", "checked", "ArrowDown did not check the newly focused radio");
    ok((await attrOf(pg, '[role="radio"]', 0, "aria-checked")) === "false", "the previously checked radio must uncheck");
  }},
  { id: "radiogroup", state: "checked", apg: "radio", name: "ArrowUp from the first radio wraps to the last AND checks it", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab"); // focus radio 0 (checked)
    await press(pg, "ArrowUp");
    ok(await activeIsNth(pg, '[role="radio"]', 1), "ArrowUp from the first radio did not wrap to the last");
    await attrEq(pg, '[role="radio"]', 1, "aria-checked", "true", "ArrowUp wrap did not check the last radio");
  }},
  // Selection-follows-focus is gated on a physical ARROW key (radio-group.tsx:182-225
  // isArrowKeyPressedRef). ARROW_KEYS excludes Home/End — so Home/End MOVE focus but do
  // NOT check; and focusing a radio programmatically (no arrow) likewise does NOT check.
  // (Validated on --golden first.)
  { id: "radiogroup", state: "checked", apg: "radio", name: "programmatic focus (no arrow) does NOT check the radio", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    focusFirst(pg, '[role="radio"]:nth-of-type(1)');
    // focus the SECOND (unchecked) radio directly — no arrow key involved.
    await pg.evaluate(() => document.querySelectorAll('[role="radio"]')[1].focus());
    await pg.waitForTimeout(100);
    ok(await activeIsNth(pg, '[role="radio"]', 1), "could not focus the second radio");
    ok((await attrOf(pg, '[role="radio"]', 1, "aria-checked")) === "false", "plain focus must NOT check the radio");
    ok((await attrOf(pg, '[role="radio"]', 0, "aria-checked")) === "true", "the originally-checked radio must stay checked");
  }},
  { id: "radiogroup", state: "checked", apg: "radio", name: "End moves focus but does NOT check (Home/End not arrow keys)", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab"); // focus radio 0 (checked)
    await press(pg, "End");
    ok(await activeIsNth(pg, '[role="radio"]', 1), "End did not move focus to the last radio");
    ok((await attrOf(pg, '[role="radio"]', 1, "aria-checked")) === "false", "End must NOT check the focused radio");
    ok((await attrOf(pg, '[role="radio"]', 0, "aria-checked")) === "true", "the originally-checked radio must stay checked after End");
  }},

  // Tabs — https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
  // Roving tabindex on the tablist (one tab tabbable). With AUTOMATIC activation (radix default)
  // moving focus to a tab activates it: aria-selected=true + its tabpanel shown. Right Arrow →
  // next tab; Left Arrow → previous; Home → first; End → last. Seed: defaultValue="account" so
  // tab[0] (Account) is selected/tabbable; 3 tabs (Account/Documents/Settings).
  { id: "tabs", state: "tab2", apg: "tabs", name: "roving tabindex: after entry exactly one tab is tabbable, the selected one", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    ok((await attrOf(pg, '[role="tab"]', 0, "aria-selected")) === "true", "tab[0] must be selected at rest");
    await press(pg, "Tab"); // into the tablist
    ok(await activeIsNth(pg, '[role="tab"]', 0), "Tab did not focus the selected tab");
    ok((await tabbableCount(pg, '[role="tab"]')) === 1, "exactly one tab must be tabbable after entry (roving tabindex)");
    ok((await attrOf(pg, '[role="tab"]', 0, "tabindex")) === "0", "the selected tab must be the tabbable one");
  }},
  { id: "tabs", state: "tab2", apg: "tabs", name: "ArrowRight activates the next tab (automatic activation) and shows its panel", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    await press(pg, "Tab"); // into the tablist, onto the selected tab
    ok(await activeIsNth(pg, '[role="tab"]', 0), "Tab did not focus the selected tab");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, '[role="tab"]', 1), "ArrowRight did not move focus to the next tab");
    await attrEq(pg, '[role="tab"]', 1, "aria-selected", "true", "ArrowRight did not activate the focused tab (automatic activation)");
    ok((await attrOf(pg, '[role="tab"]', 0, "aria-selected")) === "false", "the previously selected tab must deselect");
    const panel = await pg.evaluate(() => { const t = document.querySelectorAll('[role="tab"]')[1]; const p = document.getElementById(t.getAttribute("aria-controls")); return p && !p.hasAttribute("hidden"); });
    ok(panel, "ArrowRight did not show the newly activated tab's panel");
  }},
  // controlled: a fixed `value` (no-op onValueChange) means a click raises onValueChange but
  // CANNOT change the selection — account stays selected, documents never activates.
  { id: "tabs", state: "controlled", apg: "tabs", name: "controlled value is fixed: clicking a tab does not change selection", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    ok((await attrOf(pg, '[role="tab"]', 0, "aria-selected")) === "true", "account should start selected");
    await pg.locator('[role="tab"]').nth(1).click();
    await pg.waitForTimeout(120);
    ok((await attrOf(pg, '[role="tab"]', 1, "aria-selected")) === "false", "controlled: clicking documents must NOT select it");
    ok((await attrOf(pg, '[role="tab"]', 0, "aria-selected")) === "true", "controlled: account must remain selected");
  }},
  // activation happens on POINTERDOWN (left button), not waiting for click/mouseup (tabs.tsx
   // onMouseDown). Press the pointer down on documents without releasing → it activates.
  { id: "tabs", state: "tab2", apg: "tabs", name: "mousedown activates the tab (before mouseup)", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    const tab = pg.locator('[role="tab"]').nth(2);   // settings (tab2 has documents selected)
    const box = await tab.boundingBox();
    await pg.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await pg.mouse.down();
    await pg.waitForTimeout(80);
    const selectedDown = (await attrOf(pg, '[role="tab"]', 2, "aria-selected")) === "true";
    await pg.mouse.up();
    ok(selectedDown, "the tab did not activate on mousedown (before mouseup)");
  }},
  { id: "tabs", state: "tab2", apg: "tabs", name: "End activates the last tab, Home the first", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    await press(pg, "Tab");
    await press(pg, "End");
    ok(await activeIsNth(pg, '[role="tab"]', 2), "End did not move focus to the last tab");
    await attrEq(pg, '[role="tab"]', 2, "aria-selected", "true", "End did not activate the last tab");
    await press(pg, "Home");
    ok(await activeIsNth(pg, '[role="tab"]', 0), "Home did not move focus to the first tab");
    await attrEq(pg, '[role="tab"]', 0, "aria-selected", "true", "Home did not activate the first tab");
  }},

  // Checkbox — https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/
  // Keyboard table: Space toggles the checkbox between checked and unchecked. Seed: a single
  // unchecked checkbox; focus it, Space → checked (aria-checked + data-state), Space → unchecked.
  { id: "checkbox", state: "checked", apg: "checkbox", name: "Space toggles aria-checked / data-state", run: async (pg) => {
    const cb = pg.locator('[role="checkbox"]').first();
    await cb.waitFor();
    await focusFirst(pg, '[role="checkbox"]');
    ok(await activeIs(pg, '[role="checkbox"]'), "could not focus the checkbox");
    ok((await attrOf(pg, '[role="checkbox"]', 0, "aria-checked")) === "false", "checkbox must start unchecked");
    await press(pg, "Space");
    await attrEq(pg, '[role="checkbox"]', 0, "aria-checked", "true", "Space did not check the checkbox");
    ok((await attrOf(pg, '[role="checkbox"]', 0, "data-state")) === "checked", "data-state did not follow aria-checked on check");
    await press(pg, "Space");
    await attrEq(pg, '[role="checkbox"]', 0, "aria-checked", "false", "Space did not uncheck the checkbox");
  }},

  // Switch — https://www.w3.org/WAI/ARIA/apg/patterns/switch/
  // role=switch; Space toggles on/off (radix additionally binds Enter). Seed: a single OFF switch.
  { id: "switch", state: "on", apg: "switch", name: "Space toggles the switch on and off", run: async (pg) => {
    const sw = pg.locator('[role="switch"]').first();
    await sw.waitFor();
    await focusFirst(pg, '[role="switch"]');
    ok(await activeIs(pg, '[role="switch"]'), "could not focus the switch");
    ok((await attrOf(pg, '[role="switch"]', 0, "aria-checked")) === "false", "switch must start off");
    await press(pg, "Space");
    await attrEq(pg, '[role="switch"]', 0, "aria-checked", "true", "Space did not turn the switch on");
    ok((await attrOf(pg, '[role="switch"]', 0, "data-state")) === "checked", "data-state did not follow aria-checked on");
    await press(pg, "Space");
    await attrEq(pg, '[role="switch"]', 0, "aria-checked", "false", "Space did not turn the switch off");
  }},
  { id: "switch", state: "on", apg: "switch", name: "Enter toggles the switch (radix)", run: async (pg) => {
    await pg.locator('[role="switch"]').first().waitFor();
    await focusFirst(pg, '[role="switch"]');
    await press(pg, "Enter");
    await attrEq(pg, '[role="switch"]', 0, "aria-checked", "true", "Enter did not turn the switch on");
  }},
  // Wave D — a CONTROLLED switch (checked pinned true, no parent update): a click/Space
  // fires onCheckedChange but does NOT mutate the DOM (the parent owns the value). The
  // DOM-observable controlled contract: data-state / aria-checked stay checked.
  { id: "switch", state: "controlled", apg: "switch", name: "a controlled switch does NOT mutate the DOM on click (parent owns state)", run: async (pg) => {
    const sel = '[role="switch"]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, sel, 0, "aria-checked")) === "true", "the controlled switch must start on");
    ok((await attrOf(pg, sel, 0, "data-state")) === "checked", "the controlled switch must start data-state=checked");
    await pg.locator(sel).first().click();
    ok((await attrOf(pg, sel, 0, "aria-checked")) === "true", "controlled: a click must NOT change aria-checked (parent owns it)");
    ok((await attrOf(pg, sel, 0, "data-state")) === "checked", "controlled: a click must NOT change data-state");
    await focusFirst(pg, sel);
    await press(pg, "Space");
    ok((await attrOf(pg, sel, 0, "aria-checked")) === "true", "controlled: Space must NOT change the DOM either");
  }},

  // ToggleGroup (single) — toolbar/roving + radiogroup semantics.
  // https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/  (radix single-mode items are role=radio
  // with a roving tabindex). NOTE — radix's bare ToggleGroup is built on RovingFocus WITHOUT
  // selection-follows-focus (unlike radix RadioGroup): Arrow keys ROVE focus only; the focused
  // item is ACTIVATED (selected) by Space/Enter. Verified against the real upstream golden.
  // Seed: type=single defaultValue="b" so item[1] (Center) is checked/tabbable; 3 items.
  // The bare single-mode ToggleGroup ROOT is role="group" in the installed/bundled
  // @radix-ui/react-toggle-group dist the golden renders (the role="radiogroup" branch
  // landed in a LATER upstream source than the shipped dist) — so the golden adjudicates
  // role="group", and the port matches. (Validated on --golden first.)
  { id: "togglegroup", state: "pressed", apg: "toolbar", name: "single-mode root is role=group (bundled dist), items role=radio; roving tabindex on the selected", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    const rootRole = await pg.evaluate(() => document.querySelector('[role="radio"]')?.parentElement?.getAttribute("role"));
    ok(rootRole === "group", `single-mode root must be role=group in the bundled dist (got ${rootRole})`);
    ok((await pg.locator('[role="radio"]').count()) === 3, "expected 3 single-mode radio items");
    ok((await attrOf(pg, '[role="radio"]', 1, "aria-checked")) === "true", "item[1] (Center) must be selected at rest");
    await press(pg, "Tab"); // onto the selected item (Center, idx 1)
    ok(await activeIsNth(pg, '[role="radio"]', 1), "Tab did not focus the selected item");
    ok((await tabbableCount(pg, '[role="radio"]')) === 1, "exactly one item must be tabbable after entry (roving tabindex)");
    ok((await attrOf(pg, '[role="radio"]', 1, "tabindex")) === "0", "the selected item must be the tabbable one");
  }},
  { id: "togglegroup", state: "pressed", apg: "toolbar", name: "ArrowRight roves focus to the next item; Space then activates it", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab"); // onto the selected item (Center, idx 1)
    ok(await activeIsNth(pg, '[role="radio"]', 1), "Tab did not focus the selected item");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, '[role="radio"]', 2), "ArrowRight did not rove focus to the next item");
    // radix ToggleGroup does NOT auto-select on arrow — selection stays on Center until activation.
    ok((await attrOf(pg, '[role="radio"]', 1, "aria-checked")) === "true", "arrowing must NOT change selection (no selection-follows-focus)");
    await press(pg, "Space");
    await attrEq(pg, '[role="radio"]', 2, "aria-checked", "true", "Space did not activate the focused item");
    ok((await attrOf(pg, '[role="radio"]', 1, "aria-checked")) === "false", "the previously selected item must deselect on activation");
  }},

  // SegmentedControl — radix single-mode ToggleGroup (same toolbar/roving table; arrow roves,
  // activation key selects). Seed: defaultValue="inbox" so item[0] (Inbox) is selected/tabbable.
  { id: "segmentedcontrol", state: "selected", apg: "toolbar", name: "items are role=radio; after entry roving tabindex on the selected", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    ok((await pg.locator('[role="radio"]').count()) === 3, "expected 3 segmented-control radio items");
    ok((await attrOf(pg, '[role="radio"]', 0, "aria-checked")) === "true", "item[0] (Inbox) must be selected at rest");
    await press(pg, "Tab"); // onto Inbox (idx 0)
    ok(await activeIsNth(pg, '[role="radio"]', 0), "Tab did not focus the selected segment");
    ok((await tabbableCount(pg, '[role="radio"]')) === 1, "exactly one item must be tabbable after entry (roving tabindex)");
  }},
  { id: "segmentedcontrol", state: "selected", apg: "toolbar", name: "ArrowRight roves focus to the next segment; Space then activates it", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab"); // onto Inbox (idx 0)
    ok(await activeIsNth(pg, '[role="radio"]', 0), "Tab did not focus the selected segment");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, '[role="radio"]', 1), "ArrowRight did not rove focus to the next segment");
    ok((await attrOf(pg, '[role="radio"]', 0, "aria-checked")) === "true", "arrowing must NOT change selection (no selection-follows-focus)");
    await press(pg, "Space");
    await attrEq(pg, '[role="radio"]', 1, "aria-checked", "true", "Space did not activate the focused segment");
    ok((await attrOf(pg, '[role="radio"]', 0, "aria-checked")) === "false", "the previously selected segment must deselect on activation");
  }},

  // ScrollArea — the thumb re-offsets on scroll (upstream scroll-area.tsx:780-819 rAF
  // unlinked-scroll listener; the port recomputes on Halogen onScroll). The rAF/debounce
  // machinery is an internal detail — NOT DOM-observable — but its RESULT is: after scrolling
  // the viewport, the thumb's translate3d Y must equal getThumbOffsetFromScroll =
  // (scrollTop/maxScroll)·(track − thumb). This pins the post-scroll offset the at-rest oracle
  // never exercised. Computed from live geometry → identical on golden AND port. (--golden first.)
  { id: "scrollarea", state: "shown", apg: "scrollarea", name: "thumb re-offsets on scroll to getThumbOffsetFromScroll", run: async (pg) => {
    const vp = pg.locator(".rt-ScrollAreaViewport").first();
    const thumb = pg.locator(".rt-ScrollAreaThumb").first();
    await thumb.waitFor();
    const tyOf = () => pg.evaluate(() => {
      const t = document.querySelector(".rt-ScrollAreaThumb");
      const m = new DOMMatrixReadOnly(getComputedStyle(t).transform);
      return m.m42; // translateY
    });
    const before = await tyOf();
    ok(before < 1, `thumb must start near the top (translateY=${before})`);
    // scroll the viewport to a fixed offset and let the (rAF / onScroll) recompute flush.
    await pg.evaluate(() => { document.querySelector(".rt-ScrollAreaViewport").scrollTop = 40; });
    await pg.waitForTimeout(120);
    const after = await tyOf();
    // the EXPECTED offset from the live geometry (the same formula upstream + port use).
    const expected = await pg.evaluate(() => {
      const vp = document.querySelector(".rt-ScrollAreaViewport");
      const sb = document.querySelector('.rt-ScrollAreaScrollbar[data-orientation="vertical"]');
      const th = document.querySelector(".rt-ScrollAreaThumb");
      const maxScroll = vp.scrollHeight - vp.clientHeight;
      const track = sb.clientHeight; const thumb = th.getBoundingClientRect().height;
      return maxScroll <= 0 ? 0 : (vp.scrollTop / maxScroll) * (track - thumb);
    });
    ok(after > before, `thumb did not re-offset on scroll (stayed ${after})`);
    ok(Math.abs(after - expected) <= 1.5, `thumb translateY ${after} != getThumbOffsetFromScroll ${expected}`);
  }},
  // ScrollArea thumb-DRAG: grabbing the vertical thumb and dragging it DOWN scrolls the viewport
  // (radix Thumb pointer-drag maps a pointer delta to a scroll delta = maxScroll/maxThumb).
  // Non-circular: --golden drags the same. The exact scroll amount is geometry-dependent, so we
  // assert it scrolled meaningfully down and the thumb followed.
  { id: "scrollarea", state: "shown", apg: "scrollarea", name: "dragging the thumb scrolls the viewport", run: async (pg) => {
    const thumb = pg.locator('.rt-ScrollAreaScrollbar[data-orientation="vertical"] .rt-ScrollAreaThumb').first();
    await thumb.waitFor();
    await pg.evaluate(() => { document.querySelector(".rt-ScrollAreaViewport").scrollTop = 0; });
    await pg.waitForTimeout(60);
    const box = await thumb.boundingBox();
    ok(!!box, "could not measure the vertical thumb");
    await pg.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await pg.mouse.down();
    await pg.mouse.move(box.x + box.width / 2, box.y + box.height / 2 + 30, { steps: 4 });
    await pg.waitForTimeout(80);
    const scrolled = await pg.evaluate(() => document.querySelector(".rt-ScrollAreaViewport").scrollTop);
    ok(scrolled > 5, `dragging the thumb down should scroll the viewport (scrollTop=${scrolled})`);
    await pg.mouse.up();
  }},

  // Slider — https://www.w3.org/WAI/ARIA/apg/patterns/slider/
  // The thumb is role=slider carrying aria-valuemin/valuemax/valuenow. APG keyboard table:
  // Right/Up Arrow increases by step, Left/Down decreases, Home → min, End → max; each change
  // moves the thumb (its inline left% follows aria-valuenow). Seed: defaultValue=[40], min 0
  // max 100 step 1, so ArrowRight → 41 and the thumb left% strictly increases.
  { id: "slider", state: "stepped", apg: "slider", name: "thumb is role=slider with aria-valuemin/valuemax/valuenow; focusable", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    ok((await pg.locator('[role="slider"]').count()) === 1, "expected exactly one slider thumb");
    ok((await attrOf(pg, '[role="slider"]', 0, "aria-valuemin")) !== null, "thumb missing aria-valuemin");
    ok((await attrOf(pg, '[role="slider"]', 0, "aria-valuemax")) !== null, "thumb missing aria-valuemax");
    ok((await attrOf(pg, '[role="slider"]', 0, "aria-valuenow")) !== null, "thumb missing aria-valuenow");
    await focusFirst(pg, '[role="slider"]');
    ok(await activeIs(pg, '[role="slider"]'), "could not focus the slider thumb");
  }},
  { id: "slider", state: "stepped", apg: "slider", name: "ArrowRight increments aria-valuenow by step AND moves the thumb", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    await focusFirst(pg, '[role="slider"]');
    const before = Number(await attrOf(pg, '[role="slider"]', 0, "aria-valuenow"));
    const leftBefore = await pg.evaluate(() => getComputedStyle(document.querySelector('.rt-SliderThumb').parentElement).left);
    await press(pg, "ArrowRight");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", String(before + 1), "ArrowRight did not increment aria-valuenow by one step");
    const leftAfter = await pg.evaluate(() => getComputedStyle(document.querySelector('.rt-SliderThumb').parentElement).left);
    ok(leftAfter !== leftBefore, `ArrowRight did not move the thumb (left stayed ${leftBefore})`);
  }},
  { id: "slider", state: "stepped", apg: "slider", name: "Home goes to min, End goes to max", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    await focusFirst(pg, '[role="slider"]');
    const min = await attrOf(pg, '[role="slider"]', 0, "aria-valuemin");
    const max = await attrOf(pg, '[role="slider"]', 0, "aria-valuemax");
    await press(pg, "Home");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", min, "Home did not move the thumb to the minimum");
    await press(pg, "End");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", max, "End did not move the thumb to the maximum");
  }},
  // PageUp/PageDown = ±10·step (APG "large step"). Seed value 45 (stepped) → PageDown 35, PageUp 45.
  { id: "slider", state: "stepped", apg: "slider", name: "PageUp/PageDown move by 10 steps", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    await focusFirst(pg, '[role="slider"]');
    const before = Number(await attrOf(pg, '[role="slider"]', 0, "aria-valuenow"));
    await press(pg, "PageDown");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", String(before - 10), "PageDown did not decrease aria-valuenow by 10 steps");
    await press(pg, "PageUp");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", String(before), "PageUp did not increase aria-valuenow by 10 steps");
  }},
  // Shift+Arrow = 10·step (radix isSkipKey: shiftKey && ARROW_KEYS → page-equivalent skip).
  { id: "slider", state: "stepped", apg: "slider", name: "Shift+ArrowRight/Left move by 10 steps", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    await focusFirst(pg, '[role="slider"]');
    const before = Number(await attrOf(pg, '[role="slider"]', 0, "aria-valuenow"));
    await pg.keyboard.down("Shift"); await press(pg, "ArrowRight"); await pg.keyboard.up("Shift");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", String(before + 10), "Shift+ArrowRight did not move by 10 steps");
    await pg.keyboard.down("Shift"); await press(pg, "ArrowLeft"); await pg.keyboard.up("Shift");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", String(before), "Shift+ArrowLeft did not move by 10 steps");
  }},
  // Clamp at the grid boundaries: End then ArrowRight stays at max; Home then ArrowLeft stays at min.
  { id: "slider", state: "stepped", apg: "slider", name: "value clamps at min/max (overshoot is a no-op)", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    await focusFirst(pg, '[role="slider"]');
    const min = await attrOf(pg, '[role="slider"]', 0, "aria-valuemin");
    const max = await attrOf(pg, '[role="slider"]', 0, "aria-valuemax");
    await press(pg, "End");
    await press(pg, "ArrowRight");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", max, "ArrowRight past the maximum did not clamp");
    await press(pg, "Home");
    await press(pg, "ArrowLeft");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", min, "ArrowLeft past the minimum did not clamp");
  }},
  // Vertical orientation (?s=vertical): ArrowUp = +step, ArrowDown = -step; ArrowLeft/Right are
  // NO-OPS (radix swaps the active axis for vertical). Proves the orientation-gated keyboard axis.
  { id: "slider", state: "vertical", apg: "slider", name: "vertical: ArrowUp/ArrowDown step; ArrowLeft/ArrowRight are no-ops", run: async (pg) => {
    await pg.locator('[role="slider"][aria-orientation="vertical"]').first().waitFor();
    await focusFirst(pg, '[role="slider"]');
    const before = Number(await attrOf(pg, '[role="slider"]', 0, "aria-valuenow"));
    await press(pg, "ArrowUp");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", String(before + 1), "vertical ArrowUp did not increment by one step");
    await press(pg, "ArrowDown");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", String(before), "vertical ArrowDown did not decrement by one step");
    await press(pg, "ArrowLeft");
    await press(pg, "ArrowRight");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", String(before), "vertical ArrowLeft/ArrowRight must be no-ops");
  }},
  // Pointer-drag: a pointer-down on the track jumps the value to the pointer (radix
  // handleSlideStart → getValueFromPointer maps (x − rect.left)/width → [min,max]); dragging
  // moves it. Asserts value ≈ the clicked fraction (±3 for sub-pixel/step). Non-circular:
  // validated on --golden (real radix slider drags identically). [Slider 0–100, step 1.]
  { id: "slider", state: "stepped", apg: "slider", name: "pointer-down on the track jumps the value; dragging follows the pointer", run: async (pg) => {
    const rootEl = pg.locator(".rt-SliderRoot").first();
    await rootEl.waitFor();
    const box = await rootEl.boundingBox();
    ok(!!box, "could not measure the slider root");
    const y = box.y + box.height / 2;
    await pg.mouse.move(box.x + box.width * 0.75, y);
    await pg.mouse.down();
    await pg.waitForTimeout(60);
    const v1 = Number(await attrOf(pg, '[role="slider"]', 0, "aria-valuenow"));
    ok(Math.abs(v1 - 75) <= 3, `pointer-down at 75% should set value ≈75 (got ${v1})`);
    await pg.mouse.move(box.x + box.width * 0.25, y);
    await pg.waitForTimeout(60);
    const v2 = Number(await attrOf(pg, '[role="slider"]', 0, "aria-valuenow"));
    ok(Math.abs(v2 - 25) <= 3, `dragging to 25% should set value ≈25 (got ${v2})`);
    await pg.mouse.up();
  }},

  // Toolbar — https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/
  // Roving tabindex over the focusable items (button New, link Edit, toggle items L/C — each a
  // RovingFocusGroup.Item stamped data-radix-collection-item). At rest the toolbar ROOT is the
  // single tab stop (tabindex=0, items -1); on focus-in the tab stop migrates onto an item. Horizontal
  // orientation: ArrowRight → next item, ArrowLeft → previous, Home → first, End → last. Seed: the bare
  // golden toolbar (aria-label="Formatting") with 4 focusable items. The collection-item selector is
  // the upstream roving hook (the port stamps it identically), so the same checks run against the port.
  { id: "toolbar", state: "default", apg: "toolbar", name: "at rest the toolbar root is the single tab stop (roving tabindex)", run: async (pg) => {
    await pg.locator('[role="toolbar"]').first().waitFor();
    ok((await attrOf(pg, '[role="toolbar"]', 0, "tabindex")) === "0", "toolbar root must be tabindex=0 at rest");
    ok((await tabbableCount(pg, '[role="toolbar"] [data-radix-collection-item]')) === 0, "no item may be tabbable before focus enters (roving tabindex on root)");
  }},
  { id: "toolbar", state: "default", apg: "toolbar", name: "ArrowRight roves focus to the next item; the tab stop migrates onto it", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    ok((await pg.locator(sel).count()) === 4, "expected 4 focusable toolbar items (New, Edit, L, C)");
    await focusFirst(pg, sel);
    ok(await activeIsNth(pg, sel, 0), "could not focus the first toolbar item");
    ok((await attrOf(pg, sel, 0, "tabindex")) === "0", "the focused item must become the single tab stop");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 1), "ArrowRight did not rove focus to the next item");
    await attrEq(pg, sel, 1, "tabindex", "0", "ArrowRight did not migrate the roving tab stop onto the next item");
    ok((await attrOf(pg, sel, 0, "tabindex")) === "-1", "the previously focused item must drop to tabindex=-1");
  }},
  { id: "toolbar", state: "default", apg: "toolbar", name: "ArrowLeft roves to the previous item", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 1), "ArrowRight did not move to item 1");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 0), "ArrowLeft did not rove back to the previous item");
  }},
  { id: "toolbar", state: "default", apg: "toolbar", name: "End focuses the last item, Home the first", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await press(pg, "End");
    ok(await activeIsNth(pg, sel, 3), "End did not focus the last toolbar item");
    await press(pg, "Home");
    ok(await activeIsNth(pg, sel, 0), "Home did not focus the first toolbar item");
  }},

  // One-Time Password Field — not a named APG pattern; its nav IS the APG Roving Tabindex technique
  // (https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/#kbd_roving_tabindex) over a group
  // of single-char inputs. Horizontal: ArrowRight → next slot, ArrowLeft → previous, Home → first, End
  // → last; a printable char fills the slot and auto-advances focus. Roving slots are reachable once
  // populated, so drive the arrow checks against the FILLED story (defaultValue="123") and the
  // auto-advance check against the EMPTY story. Selector is the upstream data-radix-otp-input hook.
  // Password Toggle Field — the toggle is a native <button type=button>, so Space and Enter
  // activate it (flipping the password↔text visibility). APG button activation pattern.
  { id: "passwordtoggle", state: "hidden", apg: "button", name: "Space and Enter on the toggle flip the input type (password↔text)", run: async (pg) => {
    const btn = '#root button';
    const inp = '#root input';
    await pg.locator(inp).first().waitFor();
    ok((await attrOf(pg, inp, 0, "type")) === "password", "input should start as type=password");
    await focusFirst(pg, btn);
    ok(await activeIs(pg, btn), "could not focus the toggle button");
    await press(pg, "Space");
    ok((await attrOf(pg, inp, 0, "type")) === "text", "Space did not reveal the password (type→text)");
    await press(pg, "Enter");
    ok((await attrOf(pg, inp, 0, "type")) === "password", "Enter did not re-hide the password (type→password)");
  }},
  // Wave-D: a form RESET forces visibility back to hidden (security — never leave the
  // password revealed across a reset). Reveal it, then click the form's Reset button.
  { id: "passwordtoggle", state: "formreset", apg: "button", name: "a form reset re-hides the password (type text→password)", run: async (pg) => {
    const inp = '#root input';
    await pg.locator(inp).first().waitFor();
    ok((await attrOf(pg, inp, 0, "type")) === "password", "input should start hidden (type=password)");
    await pg.locator('#root button[type="reset"]').waitFor();
    // reveal via the toggle (the non-reset button)
    await pg.locator("#root button").filter({ hasText: /show|hide/i }).first().click();
    ok((await attrOf(pg, inp, 0, "type")) === "text", "toggle did not reveal the password");
    await pg.locator('#root button[type="reset"]').click();
    await attrEq(pg, inp, 0, "type", "password", "form reset did not re-hide the password");
  }},
  // controlled visible=false (no-op handler): clicking the toggle cannot reveal the password.
  { id: "passwordtoggle", state: "controlled", apg: "button", name: "controlled visible is fixed: clicking the toggle does not reveal", run: async (pg) => {
    const inp = '#root input';
    await pg.locator(inp).first().waitFor();
    ok((await attrOf(pg, inp, 0, "type")) === "password", "controlled hidden should start type=password");
    await pg.locator("#root button").filter({ hasText: /show|hide/i }).first().click();
    await pg.waitForTimeout(100);
    ok((await attrOf(pg, inp, 0, "type")) === "password", "controlled: clicking the toggle must NOT reveal (type stays password)");
  }},
  // onClick honors defaultPrevented: a consumer veto (preventDefault on the click) blocks the toggle.
  { id: "passwordtoggle", state: "hidden", apg: "button", name: "a defaultPrevented click does not toggle", run: async (pg) => {
    const inp = '#root input';
    await pg.locator(inp).first().waitFor();
    // capture phase so the veto runs before BOTH React's delegated handler and Halogen's element handler
    await pg.evaluate(() => document.querySelector("#root button").addEventListener("click", (e) => e.preventDefault(), true));
    await pg.locator("#root button").filter({ hasText: /show|hide/i }).first().click();
    await pg.waitForTimeout(100);
    ok((await attrOf(pg, inp, 0, "type")) === "password", "a defaultPrevented click still toggled the field");
  }},
  // Toggling visibility swaps the SAME input's type → the value is retained (test.tsx:140-146).
  { id: "passwordtoggle", state: "hidden", apg: "button", name: "toggling visibility retains the input value", run: async (pg) => {
    const inp = '#root input';
    await pg.locator(inp).first().waitFor();
    await pg.locator(inp).first().fill("secret");
    await pg.locator("#root button").filter({ hasText: /show|hide/i }).first().click();
    ok((await pg.locator(inp).first().inputValue()) === "secret", "toggling cleared the input value");
  }},
  // A pointer-triggered toggle refocuses the input (password-toggle-field.tsx:328-345).
  { id: "passwordtoggle", state: "hidden", apg: "button", name: "clicking the toggle refocuses the input", run: async (pg) => {
    const inp = '#root input';
    await pg.locator(inp).first().fill("secret");
    await pg.locator("#root button").filter({ hasText: /show|hide/i }).first().click();
    await pg.waitForTimeout(100);
    ok(await pg.evaluate(() => document.activeElement === document.querySelector("#root input")), "toggle did not refocus the input");
  }},
  // …and restores the selection that was active before the toggle blurred the input.
  { id: "passwordtoggle", state: "hidden", apg: "button", name: "clicking the toggle restores the input selection", run: async (pg) => {
    const inp = '#root input';
    await pg.locator(inp).first().fill("secret");
    await pg.evaluate(() => { const i = document.querySelector("#root input"); i.focus(); i.setSelectionRange(2, 5); });
    await pg.locator("#root button").filter({ hasText: /show|hide/i }).first().click();
    await pg.waitForTimeout(150);
    const sel = await pg.evaluate(() => { const i = document.querySelector("#root input"); return { s: i.selectionStart, e: i.selectionEnd, active: document.activeElement === i }; });
    ok(sel.active && sel.s === 2 && sel.e === 5, `selection not restored (got ${sel.s}..${sel.e} active=${sel.active})`);
  }},
  // A form SUBMIT always re-hides the password (security: don't let the browser remember the
  // revealed value). The check installs its own preventDefault so the page doesn't navigate.
  { id: "passwordtoggle", state: "formsubmit", apg: "button", name: "a form submit re-hides the password (type text→password)", run: async (pg) => {
    const inp = '#root input';
    await pg.locator(inp).first().waitFor();
    await pg.evaluate(() => document.querySelector("form").addEventListener("submit", (e) => e.preventDefault()));
    ok((await attrOf(pg, inp, 0, "type")) === "password", "input should start hidden (type=password)");
    await pg.locator("#root button").filter({ hasText: /show|hide/i }).first().click();
    ok((await attrOf(pg, inp, 0, "type")) === "text", "toggle did not reveal the password");
    await pg.locator('#root button[type="submit"]').click();
    await pg.waitForTimeout(80);
    await attrEq(pg, inp, 0, "type", "password", "form submit did not re-hide the password");
  }},

  { id: "otp", state: "filled", apg: "roving-tabindex", name: "ArrowRight/ArrowLeft rove between slots; the tab stop migrates", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    ok((await pg.locator(sel).count()) === 3, "expected 3 OTP input slots");
    await focusFirst(pg, sel);
    ok(await activeIsNth(pg, sel, 0), "could not focus the first slot");
    ok((await attrOf(pg, sel, 0, "tabindex")) === "0", "the focused slot must be the single tab stop");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 1), "ArrowRight did not rove to the next slot");
    await attrEq(pg, sel, 1, "tabindex", "0", "ArrowRight did not migrate the roving tab stop");
    ok((await attrOf(pg, sel, 0, "tabindex")) === "-1", "the previous slot must drop to tabindex=-1");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 0), "ArrowLeft did not rove back to the previous slot");
  }},
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "End focuses the last slot, Home the first", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await press(pg, "End");
    ok(await activeIsNth(pg, sel, 2), "End did not focus the last slot");
    await press(pg, "Home");
    ok(await activeIsNth(pg, sel, 0), "Home did not focus the first slot");
  }},
  // Backspace on an EMPTY slot retreats focus to the previous slot (a filled slot clears in
  // place without retreating); driven on the all-empty field.
  // Backspace on an EMPTY slot retreats focus to the previous slot (a filled slot clears in
  // place). Driven by typing slot 0 first so slot 1 is REACHABLE-but-empty (isFocusable gating
  // would make slot 1 unreachable on a wholly-empty field).
  { id: "otp", state: "empty", apg: "roving-tabindex", name: "Backspace on an empty slot retreats focus to the previous slot", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await pg.keyboard.type("1"); await pg.waitForTimeout(120);
    ok(await activeIsNth(pg, sel, 1), "typing slot 0 did not advance to the empty slot 1");
    await press(pg, "Backspace");
    ok(await activeIsNth(pg, sel, 0), "Backspace on an empty slot did not retreat to the previous slot");
  }},
  // orientation=vertical: the roving axis flips to ArrowUp/ArrowDown (data-orientation=vertical).
  { id: "otp", state: "vertical", apg: "roving-tabindex", name: "vertical: ArrowDown/ArrowUp rove between slots", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    ok(await pg.evaluate(() => !!document.querySelector('[role="group"][data-orientation="vertical"]')), "root must carry data-orientation=vertical");
    await focusFirst(pg, sel);
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, sel, 1), "ArrowDown did not rove to the next slot (vertical)");
    await press(pg, "ArrowUp");
    ok(await activeIsNth(pg, sel, 0), "ArrowUp did not rove back to the previous slot (vertical)");
  }},
  // dir=rtl: the horizontal roving axis is mirrored — ArrowLeft moves FORWARD (next slot).
  { id: "otp", state: "rtl", apg: "roving-tabindex", name: "rtl: ArrowLeft moves to the NEXT slot, ArrowRight to the previous", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    // (upstream uses `dir` for the RovingFocus context, not a stamped root attribute — so the
    // proof of rtl is the BEHAVIOR: ArrowLeft moves forward.)
    await focusFirst(pg, sel);
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 1), "rtl: ArrowLeft did not rove to the NEXT slot");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "rtl: ArrowRight did not rove to the PREVIOUS slot");
  }},
  // onFocus selects the slot's current value so the next keystroke REPLACES it (otp.tsx:670-672).
  // Proof: focus a filled slot and assert the input's selection spans its whole char.
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "focusing a filled slot selects its value so typing replaces", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await pg.waitForTimeout(60);
    const span = await pg.evaluate((s) => {
      const el = document.querySelectorAll(s)[0];
      return { start: el.selectionStart, end: el.selectionEnd, len: el.value.length };
    }, sel);
    ok(span.len === 1, `expected the first slot to hold one char (got len ${span.len})`);
    ok(span.start === 0 && span.end === span.len, `focus did not select the slot value (selection ${span.start}..${span.end} of ${span.len})`);
  }},
  // Typing on an already-filled slot REPLACES its char and advances (otp.tsx:303-311). With the
  // onFocus selection in place, the keystroke overwrites the selected char rather than appending.
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "typing on a filled slot replaces the char and advances", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await pg.waitForTimeout(60);
    await pg.keyboard.type("9"); await pg.waitForTimeout(120);
    const v0 = await pg.evaluate((s) => document.querySelectorAll(s)[0].value, sel);
    ok(v0 === "9", `typing on a filled slot did not replace its char (got '${v0}')`);
    ok(await activeIsNth(pg, sel, 1), "typing on a filled slot did not advance focus");
  }},
  // Enter in a slot submits the enclosing <form> via requestSubmit (otp.tsx:813-816). The check
  // installs its own submit listener (the <form> is real DOM on both faces) and asserts it fired.
  { id: "otp", state: "form", apg: "form-wiring", name: "Enter in a slot submits the enclosing form", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.evaluate(() => {
      window.__otpSubmit = 0;
      document.querySelector("form").addEventListener("submit", (e) => { e.preventDefault(); window.__otpSubmit++; });
    });
    await focusFirst(pg, sel);
    await press(pg, "Enter"); await pg.waitForTimeout(80);
    ok((await pg.evaluate(() => window.__otpSubmit)) === 1, "Enter did not submit the enclosing form");
  }},
  // autoSubmit: filling the last slot raises onAutoSubmit + requestSubmit (otp.tsx:431-442).
  { id: "otp", state: "autosubmit", apg: "form-wiring", name: "autoSubmit submits the form once the last slot fills", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.evaluate(() => {
      window.__otpSubmit = 0;
      document.querySelector("form").addEventListener("submit", (e) => { e.preventDefault(); window.__otpSubmit++; });
    });
    await focusFirst(pg, sel);
    await pg.keyboard.type("123"); await pg.waitForTimeout(150);
    const filled = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(""), sel);
    ok(filled === "123", `autoSubmit story did not fill all slots (got '${filled}')`);
    ok((await pg.evaluate(() => window.__otpSubmit)) === 1, "autoSubmit did not submit the form on the final slot");
  }},
  // form.reset() clears the field via the Root's reset listener (otp.tsx:419-426).
  { id: "otp", state: "form", apg: "form-wiring", name: "resetting the form clears every slot", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await pg.keyboard.type("12"); await pg.waitForTimeout(120);
    await pg.evaluate(() => document.querySelector("form").reset());
    await pg.waitForTimeout(120);
    const after = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(""), sel);
    ok(after === "", `form reset did not clear the slots (got '${after}')`);
  }},
  // isFocusable gating (otp.tsx:632-634): only slots up to lastSelectableIndex=clamp(value.length)
  // are roving-focusable. On an EMPTY field lastSelectableIndex=0, so ArrowRight/End cannot leave
  // slot 0 — you can't focus an unreachable empty slot.
  { id: "otp", state: "empty", apg: "roving-tabindex", name: "empty field: ArrowRight cannot leave slot 0 (isFocusable gating)", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    ok(await activeIsNth(pg, sel, 0), "could not focus the first slot");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "ArrowRight escaped slot 0 on an empty field (gating missing)");
    await press(pg, "End");
    ok(await activeIsNth(pg, sel, 0), "End escaped slot 0 on an empty field (gating missing)");
  }},
  // onPointerDown clamps focus to min(index, lastSelectableIndex) (otp.tsx:886-891): clicking an
  // unreachable slot (past the filled prefix) lands focus on the last selectable slot instead.
  { id: "otp", state: "empty", apg: "roving-tabindex", name: "clicking an unreachable slot clamps focus to slot 0", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.locator(sel).nth(2).click();
    await pg.waitForTimeout(80);
    ok(await activeIsNth(pg, sel, 0), "clicking slot 2 on an empty field did not clamp focus to slot 0");
  }},
  // Space is rejected as a character (validation set never includes it) and never advances.
  { id: "otp", state: "empty", apg: "roving-tabindex", name: "Space is rejected and does not fill or advance", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await pg.keyboard.press("Space"); await pg.waitForTimeout(100);
    const v0 = await pg.evaluate((s) => document.querySelectorAll(s)[0].value, sel);
    ok(v0 === "", `Space filled the slot (got '${v0}')`);
    ok(await activeIsNth(pg, sel, 0), "Space advanced focus");
  }},
  // loop is hardcoded false (RovingFocusGroup loop=false): the ends do NOT wrap.
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "roving does not wrap at the ends (loop=false)", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 0), "ArrowLeft wrapped from the first slot (loop must be false)");
    await press(pg, "End");
    ok(await activeIsNth(pg, sel, 2), "End did not reach the last slot");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 2), "ArrowRight wrapped from the last slot (loop must be false)");
  }},
  // Delete clears the focused slot in place (no retreat) when its value is SELECTED — onFocus
  // selects the char, so Delete removes the selection (otp.tsx:773-776 + onChange CLEAR_CHAR).
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "Delete clears the selected slot in place without retreating", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    // Explicit full selection so the deletion is deterministic across faces (a collapsed cursor
    // makes forward-Delete a harness-dependent no-op).
    await pg.evaluate((s) => { const el = document.querySelectorAll(s)[1]; el.focus(); el.setSelectionRange(0, el.value.length); }, sel);
    await pg.waitForTimeout(60);
    await press(pg, "Delete"); await pg.waitForTimeout(120);
    // CLEAR_CHAR removes + compacts: "123" minus slot 1 → "1","3","" (hidden "13"), focus stays.
    const after = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(","), sel);
    ok(after === "1,3,", `Delete did not remove+compact the slot (got '${after}')`);
    ok(await activeIsNth(pg, sel, 1), "Delete must keep focus on the same slot (no retreat)");
  }},
  // Ctrl/Meta+Backspace clears the ENTIRE value (otp.tsx:781-784 CLEAR).
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "Ctrl+Backspace clears the entire value", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.locator(sel).nth(2).focus();
    await pg.waitForTimeout(60);
    await pg.keyboard.press("Control+Backspace"); await pg.waitForTimeout(120);
    const all = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(""), sel);
    ok(all === "", `Ctrl+Backspace did not clear the whole value (got '${all}')`);
  }},
  // Cut clears the focused slot's char and keeps focus there (otp.tsx onCut → CLEAR_CHAR).
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "Cut clears the slot char and keeps focus", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.evaluate((s) => { const el = document.querySelectorAll(s)[1]; el.focus(); el.setSelectionRange(0, el.value.length); }, sel);
    await pg.waitForTimeout(60);
    await pg.keyboard.press("Control+x"); await pg.waitForTimeout(120);
    const after = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(","), sel);
    ok(after === "1,3,", `Cut did not remove+compact the slot char (got '${after}')`);
    ok(await activeIsNth(pg, sel, 1), "Cut must keep focus on the same slot");
  }},
  // Typing on the LAST slot sets the char and stays put (there is no next slot to advance to),
  // with the value selected so a further keystroke replaces it (otp.tsx:828-835 last-input guard).
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "typing on the last slot replaces and stays selected", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.locator(sel).nth(2).focus();
    await pg.waitForTimeout(60);
    await pg.keyboard.type("9"); await pg.waitForTimeout(120);
    const v2 = await pg.evaluate((s) => document.querySelectorAll(s)[2].value, sel);
    ok(v2 === "9", `typing on the last slot did not set the char (got '${v2}')`);
    ok(await activeIsNth(pg, sel, 2), "typing on the last slot moved focus off it");
  }},
  // Typing the SAME char already in the slot advances focus to the next slot (otp.tsx:828-832:
  // value===key fires no change event, so upstream focuses the next input explicitly).
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "retyping the current char advances to the next slot", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await pg.waitForTimeout(60);
    await pg.keyboard.type("1"); await pg.waitForTimeout(120);
    const v0 = await pg.evaluate((s) => document.querySelectorAll(s)[0].value, sel);
    ok(v0 === "1", `retyping the same char changed slot 0 (got '${v0}')`);
    ok(await activeIsNth(pg, sel, 1), "retyping the current char did not advance to the next slot");
  }},
  // autoFocus parity: @radix-ui/themes does NOT forward autoFocus to the slot inputs, so on mount
  // NO slot is focused (the prop is inert). The port matches this no-op (not the primitives pkg).
  { id: "otp", state: "autofocus", apg: "roving-tabindex", name: "autoFocus is inert (no slot focused on mount), matching themes", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.waitForTimeout(150);
    const onSlot = await pg.evaluate((s) => !!document.activeElement && document.activeElement.matches(s), sel);
    ok(!onSlot, "a slot was focused on mount, but themes autoFocus is inert");
  }},
  // paste-fill: a pasted/dumped value is SANITIZED (whitespace + rejected chars stripped) and
  // SLICED to the slot count, filling all slots and focusing the last (otp.tsx:478-485 PASTE).
  { id: "otp", state: "paste", apg: "roving-tabindex", name: "paste sanitizes junk and slices to the slot count", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.locator(sel + '[data-radix-index="0"]').focus();
    await pg.evaluate(() => {
      const el = document.querySelector('input[data-radix-otp-input][data-radix-index="0"]');
      const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
      setter.call(el, "4 5-6789");                 // spaces/dash junk + more than 3 digits
      el.dispatchEvent(new Event("input", { bubbles: true }));
    });
    await pg.waitForTimeout(120);
    const got = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(""), sel);
    ok(got === "456", `paste did not sanitize+slice to the slot count (got '${got}')`);
    ok(await activeIsNth(pg, sel, 2), "paste did not focus the last slot");
  }},
  // invalid-change: typing a char the validation set rejects leaves the slot value unchanged AND
  // re-selects it (otp.tsx onChange invalid branch → rAF select), so the next keystroke replaces.
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "an invalid char is rejected and the slot stays selected", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await pg.waitForTimeout(60);
    await pg.keyboard.type("a"); await pg.waitForTimeout(120);   // 'a' rejected under numeric
    const r = await pg.evaluate((s) => { const el = document.querySelectorAll(s)[0]; return { v: el.value, start: el.selectionStart, end: el.selectionEnd }; }, sel);
    ok(r.v === "1", `invalid char changed the slot (got '${r.v}')`);
    ok(r.start === 0 && r.end === 1, `slot not re-selected after invalid input (sel ${r.start}..${r.end})`);
  }},
  // mid-selection-insert: cursor collapsed at the END of a filled slot (not a selection) + typing a
  // char sets the NEXT slot (otp.tsx:836-862 selectionStart!==0 branch).
  { id: "otp", state: "filled", apg: "roving-tabindex", name: "typing with cursor at slot end writes the next slot", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await pg.evaluate((s) => { const el = document.querySelectorAll(s)[0]; el.focus(); el.setSelectionRange(1, 1); }, sel);
    await pg.waitForTimeout(60);
    await pg.keyboard.type("9"); await pg.waitForTimeout(120);
    const r = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(","), sel);
    ok(r === "1,9,3", `cursor-at-end typing did not write the next slot (got '${r}')`);
  }},
  // controlled: value is fixed by the parent (no-op onValueChange), so local typing cannot change it.
  { id: "otp", state: "controlled", apg: "roving-tabindex", name: "a controlled value is fixed and ignores local typing", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    const before = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(""), sel);
    ok(before === "12", `controlled value did not render (got '${before}')`);
    await pg.locator(sel + '[data-radix-index="2"]').focus();
    await pg.keyboard.type("9"); await pg.waitForTimeout(120);
    const after = await pg.evaluate((s) => [...document.querySelectorAll(s)].map((i) => i.value).join(""), sel);
    ok(after === "12", `controlled value changed on local typing (got '${after}')`);
  }},
  { id: "otp", state: "empty", apg: "roving-tabindex", name: "typing a char fills the slot and auto-advances focus to the next", run: async (pg) => {
    const sel = 'input[data-radix-otp-input]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    ok(await activeIsNth(pg, sel, 0), "could not focus the first slot");
    await pg.keyboard.type("4"); await pg.waitForTimeout(120);
    const filled = await pg.evaluate((s) => document.querySelectorAll(s)[0].value, sel);
    ok(filled === "4", `typing did not fill the first slot (got '${filled}')`);
    ok(await activeIsNth(pg, sel, 1), "typing a char did not auto-advance focus to the next slot");
  }},

  // ── Wave-B modal depth gaps (STR-330) ───────────────────────────────────────
  // Dialog (Modal) — FocusScope loop=true wrap (dialog.tsx:406) + onMountAutoFocus first
  // tabbable (dialog.tsx:408). The base 3 dialog checks above assert focus-into/trap/escape;
  // these tighten the WRAP DIRECTION and the exact initial focus target.
  { id: "dialog", apg: "dialog-modal", name: "open focuses the FIRST tabbable inside the content", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(180);
    // first tabbable in the dialog story is the soft/gray Cancel button (DOM order before Save + the input).
    ok(await activeWithin(pg, '[role="dialog"]'), "focus did not move into the dialog");
    const isFirst = await pg.evaluate(() => {
      const d = document.querySelector('[role="dialog"]');
      const f = d && d.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
      return document.activeElement === f;
    });
    ok(isFirst, "open did not focus the FIRST tabbable element in the content");
  }},
  { id: "dialog", apg: "dialog-modal", name: "Shift+Tab from the first focusable wraps to the last (loop)", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(180);
    // focus the first focusable, Shift+Tab → must wrap to the LAST focusable (FocusScope loop).
    await pg.evaluate(() => { const d = document.querySelector('[role="dialog"]'); const f = d.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'); f && f.focus(); });
    await pg.keyboard.press("Shift+Tab"); await pg.waitForTimeout(120);
    const onLast = await pg.evaluate(() => {
      const d = document.querySelector('[role="dialog"]');
      const all = [...d.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')];
      return document.activeElement === all[all.length - 1];
    });
    ok(onLast, "Shift+Tab from the first focusable did not wrap to the last (loop broken)");
  }},

  // AlertDialog — alert-dialog.tsx. The defining contracts: focus the CANCEL button on open
  // (126-129), outside-click NEVER closes (130-131 both preventDefault'd), modal Tab-trap +
  // Escape-closes-restores (inherited from Dialog). Mirrors the dialog checks, keyed off
  // role=alertdialog so the same checks run on golden and port.
  { id: "alertdialog", apg: "dialog-modal", name: "open moves focus into the alert dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("alertdialog").waitFor(); await pg.waitForTimeout(180);
    ok(await activeWithin(pg, '[role="alertdialog"]'), "focus did not move into the alert dialog on open");
  }},
  { id: "alertdialog", apg: "dialog-modal", name: "open focuses the Cancel button (alertdialog default)", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("alertdialog").waitFor(); await pg.waitForTimeout(180);
    // the Cancel button is the soft/gray button (rt-variant-soft + data-accent-color=gray).
    const onCancel = await pg.evaluate(() => {
      const d = document.querySelector('[role="alertdialog"]');
      const cancel = d && [...d.querySelectorAll("button")].find((b) => (b.textContent || "").trim() === "Cancel");
      return document.activeElement === cancel;
    });
    ok(onCancel, "open did not focus the Cancel button");
  }},
  { id: "alertdialog", apg: "dialog-modal", name: "Tab is trapped within the alert dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("alertdialog").waitFor(); await pg.waitForTimeout(180);
    for (let i = 0; i < 6; i++) await pg.keyboard.press("Tab");
    ok(await activeWithin(pg, '[role="alertdialog"]'), "Tab escaped the alert dialog (focus trap broken)");
  }},
  { id: "alertdialog", apg: "dialog-modal", name: "outside pointer-down does NOT close the alert dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("alertdialog").waitFor(); await pg.waitForTimeout(180);
    // click the scroll-padding backdrop OUTSIDE the content (top-left corner of the overlay).
    await pg.mouse.click(8, 8); await pg.waitForTimeout(180);
    ok(await visible(pg, '[role="alertdialog"]'), "outside click incorrectly closed the alert dialog");
  }},
  { id: "alertdialog", apg: "dialog-modal", name: "Escape closes and returns focus to the trigger", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("alertdialog").waitFor(); await pg.waitForTimeout(180);
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(220);
    ok(!(await visible(pg, '[role="alertdialog"]')), "Escape did not close the alert dialog");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Escape");
  }},

  // Popover — popover.tsx. Non-modal default: focus moves into content on open (404-408),
  // FocusScope loop wraps Tab within content (404-407), Escape closes + restores focus to the
  // trigger (411-418 + onCloseAutoFocus). Keyed off role=dialog inside the popper wrapper.
  { id: "popover", apg: "dialog", name: "open moves focus into the popover content", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.locator(".rt-PopoverContent").waitFor(); await pg.waitForTimeout(180);
    ok(await activeWithin(pg, '.rt-PopoverContent'), "focus did not move into the popover content on open");
  }},
  { id: "popover", apg: "dialog", name: "Escape closes the popover and returns focus to the trigger", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.locator(".rt-PopoverContent").waitFor(); await pg.waitForTimeout(180);
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(220);
    ok(!(await visible(pg, '.rt-PopoverContent')), "Escape did not close the popover");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Escape");
  }},
  // Closed-rest trigger contract (popover.tsx:147 aria-controls gated on open; the Popper
  // data-radix-popper-side/align live on Popper.Anchor, which wraps the trigger ONLY while
  // open — popper.tsx:126-127). A full closed-DOM oracle is incompatible with the port's
  // deliberately always-mounted (display:none) popper wrapper, so the closed-trigger
  // attribute contract is pinned here as an attr check (validated on golden first). This
  // caught a real port bug: the trigger stamped data-radix-popper-side/align even when closed.
  { id: "popover", apg: "dialog", name: "closed trigger has NO aria-controls and NO popper side/align attrs", run: async (pg) => {
    await triggerBtn(pg).waitFor();
    const t = await pg.evaluate(() => {
      const b = document.querySelector("#root button[aria-expanded]");
      return b && {
        expanded: b.getAttribute("aria-expanded"),
        state: b.getAttribute("data-state"),
        controls: b.hasAttribute("aria-controls"),
        side: b.hasAttribute("data-radix-popper-side"),
        align: b.hasAttribute("data-radix-popper-align"),
      };
    });
    ok(t && t.expanded === "false" && t.state === "closed", "closed trigger is not aria-expanded=false / data-state=closed");
    ok(!t.controls, "closed trigger must NOT carry aria-controls");
    ok(!t.side && !t.align, "closed trigger must NOT carry data-radix-popper-side/align (those live on Popper.Anchor, mounted only while open)");
  } },
  // Select trigger keyboard-OPEN (select.tsx:31 OPEN_KEYS, :380-389 handleOpen) — a
  // keyboard-only user opens the listbox with Space/Enter/ArrowUp/ArrowDown on the focused
  // trigger; on open focus moves to the SELECTED option. Keyed off role only → golden + port.
  ...["ArrowDown", "ArrowUp", "Enter", " "].map((key) => ({
    id: "select", apg: "listbox", name: `${key === " " ? "Space" : key} on the trigger opens the listbox`, run: async (pg) => {
      await pg.locator(".rt-SelectTrigger").focus();
      ok(!(await visible(pg, '[role="listbox"]')), "listbox should be closed before keydown");
      await pg.keyboard.press(key === " " ? "Space" : key);
      await pg.locator('[role="listbox"]').waitFor();
      ok(await visible(pg, '[role="listbox"]'), `${key} did not open the listbox`);
      await hlStarts(pg, "Apple");
    },
  })),
  { id: "select", apg: "listbox", name: "Home highlights the first option, End the last", run: async (pg) => {
    await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor();
    await hlStarts(pg, "Apple");
    await pg.keyboard.press("End"); await hlStarts(pg, "Grape");
    await pg.keyboard.press("Home"); await hlStarts(pg, "Apple");
  }},

  // Menubar in-menu keyboard SELECTION (re-exports react-menu SELECTION_KEYS) — Enter/Space on
  // the focused item fires onSelect + closes; and the disabled-item skip in vertical roving.
  { id: "menubar", apg: "menu", name: "Enter selects the highlighted item and closes the menu", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor();
    await hlStarts(pg, "New Tab");
    await pg.keyboard.press("Enter"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "Enter did not close the menu after selecting");
  }},
  // ?s=disabled disables "New Window" (item-2): data-disabled + tabindex=-1, out of the roving
  // order, so ArrowDown from New Tab SKIPS it to Print.
  { id: "menubar", state: "disabled", apg: "menu", name: "ArrowDown SKIPS a disabled item to the next enabled one", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').waitFor();
    await hlStarts(pg, "New Tab");
    ok((await pg.evaluate(() => { const e = [...document.querySelectorAll('[role="menu"] [role="menuitem"]')].find((x) => (x.textContent || "").startsWith("New Window")); return e && e.hasAttribute("data-disabled") && e.getAttribute("tabindex") === "-1"; })), "disabled item must be data-disabled + tabindex=-1");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Print");
  }},
  // Submenu — ArrowRight on a focused SubTrigger OPENS the sub (it must NOT switch to the
  // adjacent top menu — the cross-menu-vs-sub guard); ArrowLeft closes it. (?s=submenu inserts
  // a "Share" Sub in the File menu.) Non-circular: --golden (real react-menubar does the same).
  { id: "menubar", state: "submenu", apg: "menubar", name: "ArrowRight opens the submenu (not the adjacent menu); ArrowLeft closes it", run: async (pg) => {
    await pg.locator('#root [role="menuitem"]').first().focus();
    await pg.keyboard.press("ArrowDown"); await pg.locator('[role="menu"]').first().waitFor();
    await hlStarts(pg, "New Tab");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "New Window");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Share");
    await pg.keyboard.press("ArrowRight");
    await pg.waitForFunction(() => document.querySelectorAll('[role="menu"]').length >= 2, null, { timeout: 3000 });
    // the open menu must still be File's (ArrowRight opened the SUB, not switched to Edit).
    const stillFile = await pg.evaluate(() => { const m = document.querySelector('[role="menu"]'); const l = m && document.getElementById(m.getAttribute("aria-labelledby")); return l ? l.textContent.trim() : null; });
    ok(stillFile === "File", `ArrowRight wrongly switched the top menu (now ${stillFile}) instead of opening the sub`);
    ok((await pg.evaluate(() => { const t = document.querySelector('[role="menu"] [role="menuitem"][aria-haspopup="menu"]'); return t && t.getAttribute("data-state") === "open"; })),
      "ArrowRight must open the submenu (SubTrigger data-state=open)");
    await pg.keyboard.press("ArrowLeft");
    await pg.waitForFunction(() => document.querySelectorAll('[role="menu"]').length === 1, null, { timeout: 3000 });
  }},

  // DropdownMenu keyboard SELECTION (menu.tsx:667-680 SELECTION_KEYS) — Enter/Space on the
  // focused item fires onSelect + closes. Previously impossible in the port (navigate → Stay).
  { id: "dropdownmenu", apg: "menu", name: "Enter selects the highlighted item and closes the menu", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await hlStarts(pg, "Edit");
    await pg.keyboard.press("Enter"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "Enter did not close the menu after selecting");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Enter-select");
  }},
  { id: "dropdownmenu", apg: "menu", name: "Space selects the highlighted item and closes the menu", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await hlStarts(pg, "Edit");
    await pg.keyboard.press("Space"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "Space did not close the menu after selecting");
  }},
  // Trigger keys: Enter/Space/ArrowDown open (dropdown-menu.tsx:127-134); ArrowUp does NOT.
  { id: "dropdownmenu", apg: "menu-button", name: "ArrowUp on the closed trigger does NOT open the menu", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowUp"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "ArrowUp must not open the dropdown menu (only Enter/Space/ArrowDown)");
  }},
  // Tab is preventDefault-ed inside an open menu (menu.tsx:531-532): focus cannot tab out.
  { id: "dropdownmenu", apg: "menu", name: "Tab is prevented (focus stays in the menu)", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await hlStarts(pg, "Edit");
    await pg.keyboard.press("Tab"); await pg.waitForTimeout(100);
    ok(await activeWithin(pg, '[role="menu"]'), "Tab escaped the menu (should be preventDefault-ed)");
    await pg.keyboard.press("Shift+Tab"); await pg.waitForTimeout(100);
    ok(await activeWithin(pg, '[role="menu"]'), "Shift+Tab escaped the menu");
  }},
  // Page keys: PageDown ≡ last, PageUp ≡ first (menu.tsx:28-30 FIRST/LAST_KEYS include Page).
  { id: "dropdownmenu", apg: "menu", name: "PageDown focuses the last item, PageUp the first", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await hlStarts(pg, "Edit");
    await pg.keyboard.press("PageDown"); await hlStarts(pg, "Delete");
    await pg.keyboard.press("PageUp"); await hlStarts(pg, "Edit");
  }},
  // Loop default is FALSE (menu.tsx:362): ArrowDown on the last item stays put (no wrap).
  { id: "dropdownmenu", apg: "menu", name: "loop off (default): ArrowDown on the last item does NOT wrap", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await hlStarts(pg, "Edit");
    await pg.keyboard.press("End"); await hlStarts(pg, "Delete");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Delete");
  }},
  // Typeahead (APG menu: "type a character → focus the next item whose label starts with it";
  // a repeated character cycles among matches). Items: Edit, Duplicate, Archive, Delete.
  { id: "dropdownmenu", apg: "menu", name: "typeahead: a letter focuses the next matching item, repeats cycle", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await hlStarts(pg, "Edit");
    await pg.waitForTimeout(150); // let the just-opened menu's keydown listener attach (first key is dropped otherwise)
    await pg.keyboard.press("d"); await hlStarts(pg, "Duplicate");
    await pg.keyboard.press("d"); await hlStarts(pg, "Delete"); // repeated char cycles to the next match
    await pg.waitForTimeout(1100); // typeahead buffer resets after ~1s of no input
    await pg.keyboard.press("a"); await hlStarts(pg, "Archive"); // fresh single-char search
  }},

  // Context Menu — https://www.w3.org/WAI/ARIA/apg/patterns/menu/
  // A ContextMenu is a DropdownMenu point-anchored at the cursor: right-click the trigger
  // area opens a role=menu of role=menuitem rows with the SAME RovingFocus keyboard contract
  // (ArrowDown/Up rove, Home/End first/last, Enter/Space select+close, Escape close+restore).
  // The port wired navigate + Dismiss.escape but had NO APG gate. Keyed off role/data-* only,
  // so the same checks run against golden AND port. ctxOpen right-clicks the trigger area.
  { id: "contextmenu", apg: "menu", name: "ArrowDown roves Edit→Duplicate (right-click open)", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Edit");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Duplicate");
  }},
  { id: "contextmenu", apg: "menu", name: "End highlights the last item, Home the first", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Edit");
    await pg.keyboard.press("End"); await hlStarts(pg, "Delete");
    await pg.keyboard.press("Home"); await hlStarts(pg, "Edit");
  }},
  { id: "contextmenu", apg: "menu", name: "Tab is prevented (focus stays in the menu)", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Edit");
    await pg.keyboard.press("Tab"); await pg.waitForTimeout(100);
    ok(await activeWithin(pg, '[role="menu"]'), "Tab escaped the menu");
  }},
  { id: "contextmenu", apg: "menu", name: "PageDown focuses the last item, PageUp the first", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Edit");
    await pg.keyboard.press("PageDown"); await hlStarts(pg, "Delete");
    await pg.keyboard.press("PageUp"); await hlStarts(pg, "Edit");
  }},
  { id: "contextmenu", apg: "menu", name: "loop off (default): ArrowDown on the last item does NOT wrap", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Edit");
    await pg.keyboard.press("End"); await hlStarts(pg, "Delete");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Delete");
  }},
  { id: "contextmenu", apg: "menu", name: "typeahead: a letter focuses the next matching item, repeats cycle", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(150);
    await pg.keyboard.press("d"); await hlStarts(pg, "Duplicate"); // items: Edit, Duplicate, Delete
    await pg.keyboard.press("d"); await hlStarts(pg, "Delete");    // repeated char cycles
    await pg.waitForTimeout(1100); await pg.keyboard.press("e"); await hlStarts(pg, "Edit"); // fresh search
  }},
  { id: "contextmenu", apg: "menu", name: "Enter selects the highlighted item and closes the menu", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Edit");
    await pg.keyboard.press("Enter"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "Enter did not close the menu after selecting");
  }},
  { id: "contextmenu", apg: "menu", name: "Escape closes the menu", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="menu"]')), "Escape did not close the menu");
  }},
  // ?s=disabled disables Duplicate; it carries data-disabled + tabindex=-1 and is NOT in
  // the roving order, so ArrowDown from Edit SKIPS it and lands on Delete.
  { id: "contextmenu", state: "disabled", apg: "menu", name: "ArrowDown SKIPS a disabled item to the next enabled one", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor();
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Edit");
    ok((await pg.evaluate(() => { const e = [...document.querySelectorAll('[role="menuitem"]')].find((x) => (x.textContent || "").startsWith("Duplicate")); return e && e.hasAttribute("data-disabled") && e.getAttribute("tabindex") === "-1"; })), "disabled item must be data-disabled + tabindex=-1");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Delete");
  } },
  // Submenu — ArrowRight on a focused SubTrigger opens the nested SubContent; ArrowLeft closes
  // it. (?s=submenu inserts a "More" Sub between the separator and Delete.) Non-circular: --golden.
  { id: "contextmenu", state: "submenu", apg: "menu", name: "ArrowRight opens the submenu; ArrowLeft closes it", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').first().waitFor();
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Edit");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Duplicate");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "More");
    await pg.keyboard.press("ArrowRight");
    await pg.waitForFunction(() => document.querySelectorAll('[role="menu"]').length >= 2, null, { timeout: 3000 });
    ok((await pg.evaluate(() => { const t = document.querySelector('[role="menuitem"][aria-haspopup="menu"]'); return t && t.getAttribute("data-state") === "open" && t.getAttribute("aria-expanded") === "true"; })),
      "ArrowRight must open the submenu (SubTrigger data-state=open, aria-expanded=true)");
    await pg.keyboard.press("ArrowLeft");
    await pg.waitForFunction(() => document.querySelectorAll('[role="menu"]').length === 1, null, { timeout: 3000 });
    ok((await pg.evaluate(() => { const t = document.querySelector('[role="menuitem"][aria-haspopup="menu"]'); return t && t.getAttribute("data-state") === "closed"; })),
      "ArrowLeft must close the submenu (SubTrigger data-state=closed)");
  }},
  // ── Wave-B nav-group depth checks (STR-330) ──────────────────────────────────
  // HoverCard — https://www.w3.org/WAI/ARIA/apg/ (a hover-card is keyboard-reachable:
  // focusing the trigger link opens it, blur/Escape closes it). The trigger is an inline
  // <a> link (not a button), so key off role=link.
  { id: "hovercard", apg: "hover-card", name: "focus on the trigger shows the card", run: async (pg) => {
    await pg.locator("#root").getByRole("link").first().focus();
    await pg.locator(".rt-HoverCardContent").waitFor({ timeout: 3000 });
    ok(await visible(pg, ".rt-HoverCardContent"), "hover card did not show on focus");
  }},
  { id: "hovercard", apg: "hover-card", name: "Escape hides the card", run: async (pg) => {
    await pg.locator("#root").getByRole("link").first().focus();
    await pg.locator(".rt-HoverCardContent").waitFor({ timeout: 3000 });
    await pg.keyboard.press("Escape"); await pg.waitForTimeout(150);
    ok(!(await visible(pg, ".rt-HoverCardContent")), "Escape did not hide the hover card");
  }},

  // NavigationMenu — Home/End jump the trigger roving to first/last (FocusGroup
  // isFocusNavigationKey Home→0, End→count-1). The story opens via defaultValue="one";
  // focus the open trigger then Home/End. Two triggers (Item One / Item Two).
  { id: "navigationmenu", state: "open", apg: "disclosure", name: "Home/End jump trigger roving to first/last", run: async (pg) => {
    const triggers = pg.locator('#root button[aria-expanded]');
    await triggers.first().waitFor();
    await triggers.nth(1).focus();
    await pg.keyboard.press("Home"); await pg.waitForTimeout(80);
    ok(await pg.evaluate(() => document.activeElement === document.querySelectorAll('button[aria-expanded]')[0]),
      "Home did not focus the first trigger");
    await pg.keyboard.press("End"); await pg.waitForTimeout(80);
    ok(await pg.evaluate(() => { const t = document.querySelectorAll('button[aria-expanded]'); return document.activeElement === t[t.length - 1]; }),
      "End did not focus the last trigger");
  } },
  // ToggleGroup (disabled-skip + multiple) — depth gaps (STR-330 wave-b roving).
  // Disabled item is SKIPPED by roving focus: RovingFocusGroup filters candidateNodes to
  // focusable items (roving-focus-group.tsx:271; ToggleGroupItem focusable={!disabled}), so
  // an arrow toward a disabled item lands on the NEXT enabled one (never stalls). Seed
  // (?s=disabled-skip): single-mode value="a" (Left selected), the MIDDLE item (Center)
  // disabled → ArrowRight from Left must land on Right (idx 2), skipping the disabled idx 1.
  { id: "togglegroup", state: "disabled-skip", apg: "toolbar", name: "ArrowRight SKIPS a disabled item to the next enabled one", run: async (pg) => {
    const sel = '[role="radio"]';
    await pg.locator(sel).first().waitFor();
    ok((await pg.locator(sel).count()) === 3, "expected 3 single-mode radio items");
    ok((await attrOf(pg, sel, 1, "data-disabled")) !== null, "the middle item must be disabled in this state");
    ok((await attrOf(pg, sel, 1, "disabled")) !== null, "the middle item must carry the native disabled attr");
    await press(pg, "Tab"); // onto the selected item (Left, idx 0)
    ok(await activeIsNth(pg, sel, 0), "Tab did not focus the selected item");
    await press(pg, "ArrowRight");
    // idx 1 is disabled → out of the roving order → ArrowRight lands on idx 2 (Right).
    ok(await activeIsNth(pg, sel, 2), "ArrowRight did not skip the disabled middle item to idx 2");
    ok((await attrOf(pg, sel, 1, "tabindex")) === "-1", "the disabled item must never be tabbable");
  }},
  // multiple-mode (?s=multiple): items keep aria-pressed (NOT role=radio/aria-checked); root
  // role=group (bundled dist); two items pressed simultaneously and toggling is independent.
  { id: "togglegroup", state: "multiple", apg: "toolbar", name: "multiple-mode items are aria-pressed (not radio); two on at once; toggle is independent", run: async (pg) => {
    const sel = 'button[aria-pressed]';
    await pg.locator(sel).first().waitFor();
    ok((await pg.locator('[role="radio"]').count()) === 0, "multiple-mode items must NOT be role=radio");
    ok((await pg.locator(sel).count()) === 3, "expected 3 aria-pressed items");
    const rootRole = await pg.evaluate(() => document.querySelector('button[aria-pressed]')?.parentElement?.getAttribute("role"));
    ok(rootRole === "group", `multiple-mode root must be role=group in the bundled dist (got ${rootRole})`);
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "true", "item[0] must be pressed at rest");
    ok((await attrOf(pg, sel, 2, "aria-pressed")) === "true", "item[2] must be pressed at rest (two on simultaneously)");
    ok((await attrOf(pg, sel, 1, "aria-pressed")) === "false", "item[1] must be unpressed at rest");
    // toggling item[1] ON must NOT deselect the others (independent multi-select).
    await pg.locator(sel).nth(1).click();
    await attrEq(pg, sel, 1, "aria-pressed", "true", "click did not press item[1]");
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "true", "pressing item[1] must not deselect item[0] (multi-select)");
    ok((await attrOf(pg, sel, 2, "aria-pressed")) === "true", "pressing item[1] must not deselect item[2] (multi-select)");
  }},

  // Tabs disabled-skip — depth gap (STR-330 wave-b roving). A disabled tab is SKIPPED by
  // roving navigation (tabs.tsx:168-169 RovingFocusGroup.Item focusable={!disabled}), so
  // ArrowRight from tab[0] lands on tab[2] (skipping the disabled middle tab), and the
  // disabled tab is never tabbable / activatable. Seed (?s=disabled-skip): defaultValue=
  // "account" (tab[0] selected), the MIDDLE tab (Documents) disabled.
  { id: "tabs", state: "disabled-skip", apg: "tabs", name: "ArrowRight SKIPS a disabled tab to the next enabled one (and never activates it)", run: async (pg) => {
    const sel = '[role="tab"]';
    await pg.locator(sel).first().waitFor();
    ok((await pg.locator(sel).count()) === 3, "expected 3 tabs");
    ok((await attrOf(pg, sel, 1, "data-disabled")) !== null, "the middle tab must be disabled in this state");
    ok((await attrOf(pg, sel, 1, "disabled")) !== null, "the middle tab must carry the native disabled attr");
    await press(pg, "Tab"); // onto the selected tab (Account, idx 0)
    ok(await activeIsNth(pg, sel, 0), "Tab did not focus the selected tab");
    await press(pg, "ArrowRight");
    // idx 1 is disabled → out of the roving order → ArrowRight lands on idx 2 (Settings)
    // and (automatic activation) selects it; the disabled tab is never selected.
    ok(await activeIsNth(pg, sel, 2), "ArrowRight did not skip the disabled middle tab to idx 2");
    await attrEq(pg, sel, 2, "aria-selected", "true", "ArrowRight did not activate the landed tab (automatic activation)");
    ok((await attrOf(pg, sel, 1, "aria-selected")) === "false", "the disabled tab must never be selected");
    ok((await attrOf(pg, sel, 1, "tabindex")) === "-1", "the disabled tab must never be tabbable");
  }},

  // Toolbar — continuous roving across the nested ToggleGroup boundary (core gap). The 4
  // focusable items are: button New (0), link Edit (1), toggle L (2), toggle C (3). The inner
  // ToggleGroup has rovingFocus={false}, so its items rove as part of the OUTER toolbar — one
  // continuous order. From New, ArrowRight must walk Edit → L → C, crossing the group boundary.
  { id: "toolbar", state: "default", apg: "toolbar", name: "ArrowRight walks the full 4-item order, CROSSING the toggle-group boundary", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    ok((await pg.locator(sel).count()) === 4, "expected 4 focusable items (New, Edit, L, C)");
    await focusFirst(pg, sel);
    ok(await activeIsNth(pg, sel, 0), "could not focus the first item (New)");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 1), "ArrowRight did not move to the link (Edit)");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 2), "ArrowRight did not CROSS into the toggle-group (item L)");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 3), "ArrowRight did not advance to the second toggle item (C)");
  }},
  // Toolbar disabled-skip (?s=disabled) — the disabled button is excluded from the roving order
  // (focusable={!disabled}); ArrowRight from the FIRST focusable lands on the next ENABLED item,
  // never on the disabled button, which is also non-tabbable. Seed disables New, so the focusable
  // order is link Edit (0), toggle L (1), toggle C (2) — and the disabled New is not in the order.
  { id: "toolbar", state: "disabled", apg: "toolbar", name: "a disabled button is non-tabbable and skipped by the roving order", run: async (pg) => {
    await pg.locator('[role="toolbar"]').first().waitFor();
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    // the disabled button stays a collection item (count unchanged) but carries the native
    // disabled attr and tabindex=-1 — it is excluded from the focusable candidateNodes.
    ok((await attrOf(pg, sel, 0, "disabled")) !== null, "the first item (New) must be disabled");
    ok((await attrOf(pg, sel, 0, "tabindex")) === "-1", "the disabled item must be non-tabbable");
    // focus the first ENABLED item (the link Edit, idx 1) and rove forward — the disabled
    // button is never a roving stop; ArrowRight reaches the toggle items, never New.
    await pg.evaluate((s) => document.querySelectorAll(s)[1].focus(), sel);
    ok(await activeIsNth(pg, sel, 1), "could not focus the first enabled item (Edit)");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 2), "ArrowRight did not rove to the next enabled item (L)");
    ok((await pg.evaluate(() => (document.activeElement.textContent || "").trim())) !== "New", "focus must never land on the disabled button");
  } },
  // Toggle (button) — https://www.w3.org/WAI/ARIA/apg/patterns/button/
  // A toggle button activates on Space AND Enter (native <button> semantics — radix binds no
  // key handler, the host button does it). Seed `?s=rest` = the enabled, unpressed toggle.
  { id: "toggle", state: "rest", apg: "button", name: "Space activates the toggle (off→on→off round-trip)", run: async (pg) => {
    const sel = 'button[aria-pressed]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    ok(await activeIs(pg, sel), "could not focus the toggle");
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "false", "toggle must start unpressed");
    await press(pg, "Space");
    await attrEq(pg, sel, 0, "aria-pressed", "true", "Space did not press the toggle");
    ok((await attrOf(pg, sel, 0, "data-state")) === "on", "data-state did not follow aria-pressed on press");
    await press(pg, "Space");
    await attrEq(pg, sel, 0, "aria-pressed", "false", "second Space did not return the toggle to off");
    ok((await attrOf(pg, sel, 0, "data-state")) === "off", "data-state did not return to off");
  }},
  { id: "toggle", state: "rest", apg: "button", name: "Enter activates the toggle (native button key)", run: async (pg) => {
    const sel = 'button[aria-pressed]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "false", "toggle must start unpressed");
    await press(pg, "Enter");
    await attrEq(pg, sel, 0, "aria-pressed", "true", "Enter did not press the toggle");
  }},
  { id: "toggle", state: "disabled", apg: "button", name: "a disabled toggle does NOT activate on Space", run: async (pg) => {
    const sel = 'button[aria-pressed]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, sel, 0, "disabled")) !== null || (await pg.evaluate((s) => document.querySelector(s).disabled, sel)), "the disabled toggle must carry the disabled attribute");
    await focusFirst(pg, sel);
    await press(pg, "Space");
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "false", "Space must NOT press a disabled toggle");
    ok((await attrOf(pg, sel, 0, "data-disabled")) === "", "the disabled toggle must carry data-disabled=''");
  }},
  // Wave C — the disabled-AND-pressed toggle stays locked-on: Space AND Enter are both no-ops
  // (the control is disabled), and aria-pressed=true / data-state=on / data-disabled='' hold
  // throughout. Closes the disabled+Enter half (the existing check covers disabled+Space only).
  { id: "toggle", state: "disabledpressed", apg: "button", name: "a disabled-AND-pressed toggle stays locked on (Space/Enter no-op)", run: async (pg) => {
    const sel = 'button[aria-pressed]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "true", "the disabled toggle must start pressed");
    ok((await attrOf(pg, sel, 0, "data-state")) === "on", "the disabled toggle must start data-state=on");
    ok((await attrOf(pg, sel, 0, "data-disabled")) === "", "the disabled toggle must carry data-disabled=''");
    await focusFirst(pg, sel);
    await press(pg, "Space");
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "true", "Space must NOT unpress a disabled toggle");
    await press(pg, "Enter");
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "true", "Enter must NOT unpress a disabled toggle");
    ok((await attrOf(pg, sel, 0, "data-state")) === "on", "data-state must remain on");
  }},
  // Wave D — a CONTROLLED toggle (pressed pinned true, no parent update): a click fires
  // onPressedChange but does NOT mutate the DOM (the parent owns the value). The
  // DOM-observable controlled contract: data-state / aria-pressed stay on after a click.
  { id: "toggle", state: "controlled", apg: "button", name: "a controlled toggle does NOT mutate the DOM on click (parent owns state)", run: async (pg) => {
    const sel = 'button[aria-pressed]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "true", "the controlled toggle must start pressed");
    ok((await attrOf(pg, sel, 0, "data-state")) === "on", "the controlled toggle must start data-state=on");
    await pg.locator(sel).first().click();
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "true", "controlled: a click must NOT change aria-pressed (parent owns it)");
    ok((await attrOf(pg, sel, 0, "data-state")) === "on", "controlled: a click must NOT change data-state");
    await focusFirst(pg, sel);
    await press(pg, "Space");
    ok((await attrOf(pg, sel, 0, "aria-pressed")) === "true", "controlled: Space must NOT change the DOM either");
  }},

  // Checkbox — Enter is explicitly preventDefaulted (WAI-ARIA: checkboxes do NOT activate on
  // Enter; only Space toggles). The themed checkbox seed (?s=checked = the bare unchecked
  // interactive checkbox) is focusable; pressing Enter must leave it unchanged.
  { id: "checkbox", state: "checked", apg: "checkbox", name: "Enter does NOT toggle the checkbox (only Space)", run: async (pg) => {
    const sel = '[role="checkbox"]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    ok(await activeIs(pg, sel), "could not focus the checkbox");
    ok((await attrOf(pg, sel, 0, "aria-checked")) === "false", "checkbox must start unchecked");
    await press(pg, "Enter");
    ok((await attrOf(pg, sel, 0, "aria-checked")) === "false", "Enter must NOT toggle the checkbox");
    ok((await attrOf(pg, sel, 0, "data-state")) === "unchecked", "Enter must NOT change data-state");
  }},
  // Wave D — a CONTROLLED checkbox (checked pinned true, no parent update): a click/Space
  // fires onCheckedChange but does NOT mutate the DOM (the parent owns the value). The
  // DOM-observable controlled contract: aria-checked / data-state stay checked.
  { id: "checkbox", state: "controlled", apg: "checkbox", name: "a controlled checkbox does NOT mutate the DOM on click (parent owns state)", run: async (pg) => {
    const sel = '[role="checkbox"]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, sel, 0, "aria-checked")) === "true", "the controlled checkbox must start checked");
    ok((await attrOf(pg, sel, 0, "data-state")) === "checked", "the controlled checkbox must start data-state=checked");
    await pg.locator(sel).first().click();
    ok((await attrOf(pg, sel, 0, "aria-checked")) === "true", "controlled: a click must NOT change aria-checked (parent owns it)");
    ok((await attrOf(pg, sel, 0, "data-state")) === "checked", "controlled: a click must NOT change data-state");
    await focusFirst(pg, sel);
    await press(pg, "Space");
    ok((await attrOf(pg, sel, 0, "aria-checked")) === "true", "controlled: Space must NOT change the DOM either");
  }},

  // RadioGroup — additional keyboard conformance (3-item seed via `?s=keys`).
  // Enter does NOT activate a radio (WAI-ARIA radio semantics). A disabled radio is SKIPPED
  // by arrow navigation (roving over focusable items only). Home/End move focus but do NOT
  // check (selection-follows-focus is arrow-key-only). loop=false clamps at the ends.
  { id: "radiogroup", state: "keys", apg: "radio", name: "Enter does NOT activate/select a radio", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab"); // onto the checked radio (value=1)
    ok(await activeIsNth(pg, '[role="radio"]', 0), "Tab did not land on the checked radio");
    await press(pg, "Enter");
    ok((await attrOf(pg, '[role="radio"]', 0, "aria-checked")) === "true", "the checked radio must stay checked after Enter");
    ok((await attrOf(pg, '[role="radio"]', 1, "aria-checked")) === "false", "Enter must not check another radio");
    ok((await attrOf(pg, '[role="radio"]', 2, "aria-checked")) === "false", "Enter must not check another radio");
  }},
  { id: "radiogroup", state: "keys", apg: "radio", name: "ArrowDown SKIPS a disabled radio to the next enabled one", run: async (pg) => {
    // seed: 3 items, item[1] disabled, defaultValue=1 (item[0] checked).
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab"); // focus item[0]
    ok(await activeIsNth(pg, '[role="radio"]', 0), "Tab did not focus the first radio");
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, '[role="radio"]', 2), "ArrowDown did not SKIP the disabled radio to the next enabled one");
    await attrEq(pg, '[role="radio"]', 2, "aria-checked", "true", "the skipped-to radio must be checked (selection-follows-focus)");
    ok((await attrOf(pg, '[role="radio"]', 1, "aria-checked")) === "false", "the disabled radio must never become checked");
  }},
  { id: "radiogroup", state: "keys", apg: "radio", name: "End moves focus but does NOT check (3-item seed)", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab");
    await press(pg, "End");
    ok(await activeIsNth(pg, '[role="radio"]', 2), "End did not move focus to the last radio");
    ok((await attrOf(pg, '[role="radio"]', 2, "aria-checked")) === "false", "End must NOT check the focused radio");
    ok((await attrOf(pg, '[role="radio"]', 0, "aria-checked")) === "true", "the originally-checked radio must stay checked after End");
  } },
  // Wave D — loop={false}: arrow keys CLAMP at the ends (no wrap). 3-item group, value=1 checked.
  { id: "radiogroup", state: "loopoff", apg: "radio", name: "loop=false: ArrowUp at the first radio does NOT wrap to the last", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    ok((await pg.locator('[role="radio"]').count()) === 3, "expected 3 radios in the loopoff seed");
    await press(pg, "Tab"); // onto the checked radio (value=1, index 0)
    ok(await activeIsNth(pg, '[role="radio"]', 0), "Tab did not land on the checked radio");
    await press(pg, "ArrowUp");
    ok(await activeIsNth(pg, '[role="radio"]', 0), "loop=false: ArrowUp at the first radio must CLAMP (not wrap to last)");
    await attrEq(pg, '[role="radio"]', 0, "aria-checked", "true", "the first radio stays checked after a clamped ArrowUp");
    ok((await attrOf(pg, '[role="radio"]', 2, "aria-checked")) === "false", "the last radio must NOT become checked (no wrap)");
  } },
  { id: "radiogroup", state: "loopoff", apg: "radio", name: "loop=false: ArrowDown at the last radio does NOT wrap to the first", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab");
    await press(pg, "End"); // focus moves to last (Home/End jump but do not check)
    ok(await activeIsNth(pg, '[role="radio"]', 2), "End did not focus the last radio");
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, '[role="radio"]', 2), "loop=false: ArrowDown at the last radio must CLAMP (not wrap to first)");
  } },
  // Wave D — horizontal + dir=rtl: the live horizontal arrows SWAP (ArrowLeft⇒Next, ArrowRight⇒Prev).
  { id: "radiogroup", state: "rtl", apg: "radio", name: "RTL horizontal: ArrowLeft moves to the NEXT radio (direction-swapped)", run: async (pg) => {
    await pg.locator('[role="radiogroup"][dir="rtl"]').first().waitFor();
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab"); // onto the checked radio (value=1, index 0)
    ok(await activeIsNth(pg, '[role="radio"]', 0), "Tab did not land on the checked radio");
    await press(pg, "ArrowLeft"); // RTL: ArrowLeft is Next
    ok(await activeIsNth(pg, '[role="radio"]', 1), "RTL: ArrowLeft must move to the NEXT radio");
    await attrEq(pg, '[role="radio"]', 1, "aria-checked", "true", "the next radio must be checked (selection-follows-focus)");
  } },
  { id: "radiogroup", state: "rtl", apg: "radio", name: "RTL horizontal: ArrowRight moves to the PREVIOUS radio (direction-swapped)", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    await press(pg, "Tab");
    await press(pg, "ArrowLeft"); // to index 1 (Next in RTL)
    ok(await activeIsNth(pg, '[role="radio"]', 1), "ArrowLeft did not advance to index 1");
    await press(pg, "ArrowRight"); // RTL: ArrowRight is Prev
    ok(await activeIsNth(pg, '[role="radio"]', 0), "RTL: ArrowRight must move to the PREVIOUS radio");
    await attrEq(pg, '[role="radio"]', 0, "aria-checked", "true", "the previous radio must be checked after the RTL ArrowRight");
  } },
  // Disclosure (Collapsible) — https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/
  // The trigger is a native type=button, so Enter and Space both fire `click` → onOpenToggle.
  // APG: activating the trigger toggles aria-expanded and shows/hides the content; while closed
  // aria-controls is ABSENT (radix gates it on open). Seed: the default (closed) story.
  { id: "collapsible", state: "open", apg: "disclosure", name: "Enter on the trigger toggles aria-expanded and discloses the content", run: async (pg) => {
    const trig = pg.locator('#root button[aria-expanded]').first();
    await trig.waitFor();
    ok((await attrOf(pg, '#root button[aria-expanded]', 0, "aria-expanded")) === "false", "trigger must start collapsed");
    ok((await attrOf(pg, '#root button[aria-expanded]', 0, "aria-controls")) === null, "aria-controls must be ABSENT while closed");
    await trig.focus();
    await press(pg, "Enter");
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "true", "Enter did not expand the disclosure");
    ok((await attrOf(pg, '#root button[aria-expanded]', 0, "aria-controls")) !== null, "aria-controls must appear (→ the content) when open");
    await pg.locator('[data-state="open"]:not([hidden])').first().waitFor();
  }},
  { id: "collapsible", state: "open", apg: "disclosure", name: "Space toggles the disclosure closed again", run: async (pg) => {
    const trig = pg.locator('#root button[aria-expanded]').first();
    await trig.waitFor();
    await trig.focus();
    await press(pg, "Enter"); // open
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "true", "Enter did not expand");
    await press(pg, "Space"); // collapse
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "false", "Space did not collapse the disclosure");
  }},
  // Wave-D: CONTROLLED mode (open owned by the parent, never updated). The page mounts the
  // collapsible open (open=true); clicking the trigger fires onOpenChange(false) but the
  // parent ignores it, so the content STAYS open (aria-expanded stays true, content stays
  // disclosed). Keyed off the open trigger only ⇒ same check runs on golden + port.
  { id: "collapsible", state: "controlled", apg: "disclosure", name: "controlled mode: clicking the trigger does NOT close the parent-owned content", run: async (pg) => {
    const trig = pg.locator('#root button[aria-expanded]').first();
    await trig.waitFor();
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "true", "controlled collapsible must mount OPEN (open=true)");
    await trig.click();
    await pg.waitForTimeout(150);
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "true", "controlled: click must NOT close (parent owns open)");
    await pg.locator('[data-state="open"]:not([hidden])').first().waitFor();
  }},

  // ── Wave-C modal depth gaps (STR-330) ───────────────────────────────────────
  // Dialog — DialogClose (dialog.tsx:472-492): a button inside content composes its onClick
  // with onOpenChange(false). The golden's Cancel/Save are each wrapped in Dialog.Close, so a
  // click on either closes the dialog AND restores focus to the trigger. The port reproduces
  // this behaviorally (closeLabels match, no DOM marker — golden's Close is asChild). Keyed off
  // role=dialog + the button text, so the same check runs on golden and port.
  { id: "dialog", apg: "dialog-modal", name: "clicking the Cancel close-button closes the dialog + restores focus", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(180);
    await pg.getByRole("dialog").getByRole("button", { name: "Cancel" }).click(); await pg.waitForTimeout(220);
    ok(!(await visible(pg, '[role="dialog"]')), "Cancel close-button did not close the dialog");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Cancel close");
  }},
  { id: "dialog", apg: "dialog-modal", name: "clicking the Save close-button closes the dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("dialog").waitFor(); await pg.waitForTimeout(180);
    await pg.getByRole("dialog").getByRole("button", { name: "Save" }).click(); await pg.waitForTimeout(220);
    ok(!(await visible(pg, '[role="dialog"]')), "Save close-button did not close the dialog");
  }},

  // AlertDialog — AlertDialogCancel AND AlertDialogAction both close (alert-dialog.tsx: both are
  // DialogPrimitive.Close). Cancel is the safe action focused on open; Action is the destructive
  // confirm. Clicking either closes + restores focus to the trigger. Keyed off role=alertdialog.
  { id: "alertdialog", apg: "dialog-modal", name: "clicking Cancel closes the alert dialog + restores focus", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("alertdialog").waitFor(); await pg.waitForTimeout(180);
    await pg.getByRole("alertdialog").getByRole("button", { name: "Cancel" }).click(); await pg.waitForTimeout(220);
    ok(!(await visible(pg, '[role="alertdialog"]')), "Cancel did not close the alert dialog");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after Cancel");
  }},
  { id: "alertdialog", apg: "dialog-modal", name: "clicking the destructive Action closes the alert dialog", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.getByRole("alertdialog").waitFor(); await pg.waitForTimeout(180);
    // the Action button is the red "Revoke access" confirm; scope to the alertdialog so it is
    // not confused with the same-labelled trigger.
    await pg.getByRole("alertdialog").getByRole("button", { name: "Revoke access" }).click(); await pg.waitForTimeout(220);
    ok(!(await visible(pg, '[role="alertdialog"]')), "Action did not close the alert dialog");
  }},

  // Popover — PopoverClose (popover.tsx Close → onOpenChange(false)). The ?s=close story adds a
  // "Comment" submit button wrapped in Popover.Close; clicking it closes the popover + restores
  // focus to the trigger. The check opens via ?c=popover&s=close (state field), so it runs on
  // the golden's Close-bearing page AND the port's. Validated on --golden first.
  { id: "popover", apg: "dialog", state: "close", name: "clicking the PopoverClose button closes the popover + restores focus", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.locator(".rt-PopoverContent").waitFor(); await pg.waitForTimeout(180);
    await pg.locator(".rt-PopoverContent").getByRole("button", { name: "Comment" }).click(); await pg.waitForTimeout(220);
    ok(!(await visible(pg, '.rt-PopoverContent')), "PopoverClose did not close the popover");
    ok(await activeIs(pg, "#root button"), "focus did not return to the trigger after PopoverClose");
  } },
  // ── Wave-C menus depth (STR-330): DropdownMenu CheckboxItem / RadioItem roving ───────
  // Menu pattern (https://www.w3.org/WAI/ARIA/apg/patterns/menu/): a menuitemcheckbox carries
  // role + aria-checked and participates in the roving order exactly like a menuitem. Open via
  // ArrowDown (keyboard-open highlights the first item), then ArrowDown roves to the second —
  // and the items keep their aria-checked (toolbar=true, sidebar=false) regardless of highlight.
  { id: "dropdownmenuchecks", state: "checkbox", apg: "menu", name: "ArrowDown roves the checkbox items; aria-checked is preserved", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "Show Toolbar");
    ok((await attrOf(pg, '[role="menuitemcheckbox"]', 0, "aria-checked")) === "true", "the checked checkbox must report aria-checked=true");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Show Sidebar");
    ok((await attrOf(pg, '[role="menuitemcheckbox"]', 1, "aria-checked")) === "false", "the unchecked checkbox must report aria-checked=false even when highlighted");
  }},
  // RadioGroup of menuitemradio: single-selection aria-checked (medium=true, others=false). The
  // three options rove like menuitems; the selected one keeps aria-checked=true through roving.
  { id: "dropdownmenuchecks", state: "radio", apg: "menu", name: "ArrowDown roves the radio items; single-selection aria-checked holds", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "Small");
    ok((await attrOf(pg, '[role="menuitemradio"]', 0, "aria-checked")) === "false", "Small must be aria-checked=false");
    ok((await attrOf(pg, '[role="menuitemradio"]', 1, "aria-checked")) === "true", "Medium (selected) must be aria-checked=true");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Medium");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Large");
    ok((await attrOf(pg, '[role="menuitemradio"]', 1, "aria-checked")) === "true", "Medium must REMAIN the single selected radio after roving");
  }},
  // ── Wave-C menus depth (STR-330): ContextMenu CheckboxItem / RadioItem roving ───────
  // Right-click open (point-anchored), then ArrowDown roves the checkbox/radio items —
  // aria-checked is preserved through roving exactly as for the dropdown menu.
  { id: "contextmenuchecks", state: "checkbox", apg: "menu", name: "ArrowDown roves the context checkbox items; aria-checked is preserved", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Show Toolbar");
    ok((await attrOf(pg, '[role="menuitemcheckbox"]', 0, "aria-checked")) === "true", "the checked checkbox must report aria-checked=true");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Show Sidebar");
    ok((await attrOf(pg, '[role="menuitemcheckbox"]', 1, "aria-checked")) === "false", "the unchecked checkbox must report aria-checked=false when highlighted");
  }},
  { id: "contextmenuchecks", state: "radio", apg: "menu", name: "ArrowDown roves the context radio items; single-selection aria-checked holds", run: async (pg) => {
    await pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" });
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    ok((await attrOf(pg, '[role="menuitemradio"]', 1, "aria-checked")) === "true", "Medium (selected) must be aria-checked=true");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Small");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Medium");
    ok((await attrOf(pg, '[role="menuitemradio"]', 1, "aria-checked")) === "true", "Medium must REMAIN the single selected radio after roving");
  }},
  // ── Wave-C menus depth (STR-330): Menubar CheckboxItem / RadioItem roving ────────────
  // Click the View trigger to open, ArrowDown roves the checkbox/radio items; aria-checked
  // is preserved through roving (bare @radix-ui/react-menubar re-exports react-menu).
  // NB: a CHECKED item's textContent leads with its ✓ ItemIndicator child, so the highlighted
  // text for "Show Toolbar" (checked) is "✓Show Toolbar"; "Show Sidebar" (unchecked) has no ✓.
  { id: "menubarchecks", state: "checkbox", apg: "menu", name: "ArrowDown roves the menubar checkbox items; aria-checked is preserved", run: async (pg) => {
    await pg.locator("#root").getByRole("menuitem").first().click();
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "✓Show Toolbar");
    ok((await attrOf(pg, '[role="menuitemcheckbox"]', 0, "aria-checked")) === "true", "the checked checkbox must report aria-checked=true");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Show Sidebar");
    ok((await attrOf(pg, '[role="menuitemcheckbox"]', 1, "aria-checked")) === "false", "the unchecked checkbox must report aria-checked=false when highlighted");
  }},
  { id: "menubarchecks", state: "radio", apg: "menu", name: "ArrowDown roves the menubar radio items; single-selection aria-checked holds", run: async (pg) => {
    await pg.locator("#root").getByRole("menuitem").first().click();
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    ok((await attrOf(pg, '[role="menuitemradio"]', 1, "aria-checked")) === "true", "Medium (selected) must be aria-checked=true");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Small");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "✓Medium");
    ok((await attrOf(pg, '[role="menuitemradio"]', 1, "aria-checked")) === "true", "Medium must REMAIN the single selected radio after roving");
  }},
  // ── Wave-C menus depth (STR-330): Select placeholder (combobox) ──────────────────
  // APG listbox/combobox: with NO value the trigger reports data-placeholder and (per the
  // Select pattern) keyboard-opens. On open NO option is aria-selected (nothing chosen yet).
  { id: "selectplaceholder", state: "placeholder", apg: "listbox", name: "placeholder trigger reports data-placeholder and keyboard-opens with no selection", run: async (pg) => {
    const trig = pg.locator('.rt-SelectTrigger').first(); await trig.waitFor();
    ok((await attrOf(pg, '.rt-SelectTrigger', 0, "data-placeholder")) === "", "trigger must carry data-placeholder while unselected");
    await trig.focus(); await press(pg, "ArrowDown");
    await pg.locator('[role="listbox"]').waitFor(); await pg.waitForTimeout(120);
    const sel = await pg.evaluate(() => [...document.querySelectorAll('[role="option"]')].some((o) => o.getAttribute("aria-selected") === "true"));
    ok(!sel, "no option may be aria-selected when the placeholder (no value) is showing");
  } },
  // ── Wave-C nav-group depth checks (STR-330) ──────────────────────────────────
  // Tooltip a11y invariants the open golden only INCIDENTALLY covered — promoted to explicit
  // checked invariants (no port change; the port already satisfies both):
  //  (1) the VisuallyHidden role=tooltip copy (the trigger's aria-describedby target, the
  //      accessible name) carries NO arrow/svg — upstream suppresses the Arrow inside the
  //      VisuallyHidden subtree (VisuallyHiddenContentContext isInside ⇒ Arrow returns null),
  //      so the SR copy never duplicates the decorative arrow (tooltip.tsx:483-484,596-604).
  //  (2) the trigger button has NO type attribute — deliberate upstream (triggers are often
  //      anchors; tooltip.tsx:287-289). A regression adding type=button would now be caught.
  // Open via focus (instant-open) so the role=tooltip copy is present, then assert both.
  { id: "tooltip", apg: "tooltip", name: "the VisuallyHidden role=tooltip copy has no arrow, and the trigger has no type attr", run: async (pg) => {
    await triggerBtn(pg).focus();
    await pg.getByRole("tooltip").waitFor({ timeout: 3000 });
    // (1) no svg/arrow inside the role=tooltip accessible-name copy.
    ok(await pg.evaluate(() => {
      const sr = document.querySelector('[role="tooltip"]');
      return !!sr && sr.querySelector("svg") === null;
    }), "the role=tooltip accessible-name copy must NOT contain the decorative arrow svg");
    // (2) the trigger button carries no `type` attribute (triggers may be anchors).
    ok((await attrOf(pg, "#root button", 0, "type")) === null, "the tooltip trigger must have NO type attribute");
  }},
  // Toast — the SR announce node + the viewport landmark, the two a11y contracts the DOM/ARIA
  // oracles can't pin (the DOM oracle strips role=status; the ARIA snapshot doesn't expose
  // aria-live polarity). Append-only, no story/port change (the port already satisfies both):
  //  (1) the announce node is role=status with aria-live=assertive for a FOREGROUND toast
  //      (background ⇒ polite; toast.tsx:564-566). The golden story is Foreground.
  //  (2) the viewport region carries the hotkey aria-label "Notifications (F8)" (the {hotkey}
  //      placeholder substituted into the label; toast.tsx:293). Port hardcodes this label.
  // The toast is rendered controlled-open at first paint (duration=Infinity), so just wait for
  // the open <li>, then read the sibling role=status + the region aria-label.
  { id: "toast", apg: "alert", name: "foreground toast announces assertively; viewport carries the F8 hotkey label", run: async (pg) => {
    await pg.locator('li[data-state="open"][data-swipe-direction]').first().waitFor();
    // (1) role=status announce node, aria-live=assertive (foreground polarity).
    ok(await pg.evaluate(() => {
      const s = document.querySelector('[role="status"]');
      return !!s && s.getAttribute("aria-live") === "assertive";
    }), "the foreground announce node must be role=status with aria-live=assertive");
    // (2) the viewport landmark carries the hotkey-substituted aria-label.
    ok(await pg.evaluate(() => {
      const r = document.querySelector('[role="region"]');
      return !!r && /Notifications \(F8\)/.test(r.getAttribute("aria-label") || "");
    }), 'the toast viewport region must carry the aria-label "Notifications (F8)"');
  }},
  // Swipe-to-dismiss: dragging the toast in the swipe direction (right) past swipeThreshold
  // (50px) dismisses it (radix Toast pointer-swipe → data-swipe=end → onClose). Non-circular:
  // --golden swipes the same. Asserts the toast unmounts after a >threshold drag.
  { id: "toast", apg: "alert", name: "swiping the toast past the threshold dismisses it", run: async (pg) => {
    const li = pg.locator('li[data-swipe-direction]').first();
    await li.waitFor();
    const box = await li.boundingBox();
    ok(!!box, "could not measure the toast");
    await pg.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await pg.mouse.down();
    await pg.mouse.move(box.x + box.width / 2 + 140, box.y + box.height / 2, { steps: 6 });
    await pg.mouse.up();
    await li.waitFor({ state: "detached", timeout: 3000 });
  }},
  // Auto-dismiss: a toast with a finite duration mounts open, then closes ITSELF when the
  // timer fires — no user action, no Escape, no close click. (?s=autodismiss sets duration=
  // 1500ms.) Assert it is open at first paint, then unmounts on its own once the timer + the
  // pinned exit animation complete. Non-circular: passes on --golden (the real
  // @radix-ui/react-toast schedules the same setTimeout(close)). The 1500ms duration leaves
  // ample margin over page-load latency so the "open at mount" observation is never racy.
  { id: "toast", state: "autodismiss", apg: "alert", name: "a finite-duration toast auto-dismisses itself when the timer fires", run: async (pg) => {
    const li = pg.locator('li[data-swipe-direction]').first();
    await li.waitFor({ timeout: 3000 });
    ok((await li.getAttribute("data-state")) === "open", "the toast must be open at first paint (not instantly closed)");
    // no user interaction — the auto-dismiss timer alone must unmount it (duration + exit anim).
    await li.waitFor({ state: "detached", timeout: 5000 });
  }},
  // Pause/resume: pointer over the viewport PAUSES the auto-dismiss (radix preserves the
  // remaining time); leaving RESUMES it. Hover immediately, hold past the full duration — the
  // toast must NOT dismiss while paused — then leave and watch it dismiss on its own. The
  // remaining-time preservation is measured with performance.now() (Dom.now). Non-circular:
  // passes on --golden (the real @radix-ui/react-toast pauses on viewport pointer-enter too).
  { id: "toast", state: "autodismiss", apg: "alert", name: "hovering the viewport pauses the auto-dismiss; leaving resumes it", run: async (pg) => {
    const li = pg.locator('li[data-swipe-direction]').first();
    await li.waitFor({ timeout: 3000 });
    await li.hover();                            // pointer into the viewport → pause
    await pg.waitForTimeout(2000);               // longer than the full 1500ms duration
    ok((await li.getAttribute("data-state")) === "open", "the toast dismissed while the pointer was paused over it");
    await pg.mouse.move(0, 0);                   // leave → resume the remaining time
    await li.waitFor({ state: "detached", timeout: 5000 });
  }},
  // HoverCard — the DEFINING contract vs a tooltip: moving the pointer from the trigger INTO
  // the content keeps the card OPEN (both trigger and content bind onPointerEnter/Leave, so the
  // card survives the cross-move). Hover the trigger link → wait for the content → move the
  // pointer onto the content's box → assert it is STILL open (data-state=open, not closing).
  // Keyed off the upstream .rt-HoverCardContent + data-state only, so the same check runs on
  // golden and port. (Wave-A/B verified focus-open + Escape; this pins the hover-card-vs-tooltip
  // distinction the existing oracles never exercised.)
  { id: "hovercard", apg: "hover-card", name: "pointer over the content keeps the card open (hover-card, not tooltip)", run: async (pg) => {
    await pg.locator("#root").getByRole("link").first().hover();
    const content = pg.locator(".rt-HoverCardContent").first();
    await content.waitFor({ timeout: 3000 });
    // Move the pointer onto the content — the cross-move must NOT close it. Use locator.hover()
    // (auto-waits for the content to be stable and re-resolves its center) instead of a one-shot
    // boundingBox + mouse.move: under load the box could be read mid-reposition, landing the move
    // off-content → the trigger-leave closeDelay fires → flaky close. hover() re-enters reliably.
    await content.hover();
    await pg.waitForTimeout(200);   // comfortably past the 150ms closeDelay; pointer stays on content
    ok(await visible(pg, ".rt-HoverCardContent"), "the card closed when the pointer moved onto its content (hover-card must stay open)");
    ok((await attrOf(pg, ".rt-HoverCardContent", 0, "data-state")) === "open", "the content must remain data-state=open while the pointer is over it");
  }},
  // Hover DEFERS the open by openDelay (Themes 200ms): brushing past the trigger must not
  // flash the card. Assert still-closed shortly after pointer-enter, then opens after the
  // delay. Non-circular: passes on --golden (real Themes HoverCard delays identically).
  { id: "hovercard", apg: "hover-card", name: "hover defers the open by openDelay (no instant flash)", run: async (pg) => {
    await pg.locator("#root").getByRole("link").first().hover();
    await pg.waitForTimeout(60);
    ok(!(await visible(pg, ".rt-HoverCardContent")), "hover card flashed open before openDelay elapsed");
    await pg.locator(".rt-HoverCardContent").waitFor({ timeout: 3000 });
    ok(await visible(pg, ".rt-HoverCardContent"), "hover card never opened after openDelay");
  }},
  // Leaving the trigger closes after closeDelay (Themes 150ms), NOT instantly — the grace
  // window is what lets the pointer travel trigger→content without the card vanishing. Assert
  // still-open just after leave, then eventually gone. Non-circular (real Themes does the same).
  { id: "hovercard", apg: "hover-card", name: "leaving closes after closeDelay (not instantly)", run: async (pg) => {
    await pg.locator("#root").getByRole("link").first().hover();
    await pg.locator(".rt-HoverCardContent").waitFor({ timeout: 3000 });
    await pg.mouse.move(0, 0);                  // leave the trigger
    await pg.waitForTimeout(50);                // inside the closeDelay window
    ok(await visible(pg, ".rt-HoverCardContent"), "card closed instantly on leave (closeDelay not honored)");
    await pg.locator(".rt-HoverCardContent").waitFor({ state: "detached", timeout: 3000 });
  }},
  // NavigationMenu content-link roving — once focus is INSIDE the open content (a separate
  // FocusGroup over the content's links), ArrowRight/ArrowLeft rove between the links and are
  // CLAMPED (non-looping, slice-from-current) just like the trigger bar. The `open` story
  // (defaultValue="one") opens Item One whose content has TWO links (Content One / Content Two).
  // ArrowDown from the open trigger enters the content (lands on the first link); ArrowRight
  // then moves to the second; a second ArrowRight stays put (clamp); ArrowLeft returns to the
  // first. Keyed off role=link inside the open content (aria-labelledby), same on the port.
  { id: "navigationmenu", state: "open", apg: "disclosure", name: "content-link roving: Arrow keys move between content links (CLAMPED, non-looping)", run: async (pg) => {
    await pg.locator('#root button[aria-expanded="true"]').first().waitFor();
    await focusFirst(pg, '#root button[aria-expanded="true"]');
    await press(pg, "ArrowDown"); // enter the content → first link
    ok(await activeWithin(pg, '[aria-labelledby]'), "ArrowDown did not move focus into the content");
    const links = '[aria-labelledby] a[href]';
    await pg.locator(links).first().waitFor();
    ok((await pg.locator(links).count()) >= 2, "the open content must expose at least two links to rove");
    ok(await activeIsNth(pg, links, 0), "entry did not land on the FIRST content link");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, links, 1), "ArrowRight did not move to the second content link");
    // CLAMP: a second ArrowRight at the last link stays put (NavigationMenu content FocusGroup must NOT loop).
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, links, 1), "ArrowRight wrapped (content FocusGroup must clamp, not loop)");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, links, 0), "ArrowLeft did not move back to the first content link");
  }},
  // NavigationMenu HORIZONTAL roving no-ops: on a trigger, ArrowUp does NOTHING (vertical axis,
  // not in the horizontal FocusGroup's plane), and ArrowDown on the open trigger is the ENTRY
  // key (handled above) — it never roves the trigger bar. This pins the axis-restriction: a
  // stray ArrowUp must not move trigger focus. Keyed off the trigger bar (button[aria-expanded]).
  { id: "navigationmenu", state: "open", apg: "disclosure", name: "ArrowUp on a trigger is a no-op (horizontal axis only)", run: async (pg) => {
    await pg.locator('#root button[aria-expanded]').first().waitFor();
    await focusFirst(pg, '#root button[aria-expanded]');
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 0), "could not focus the first trigger");
    await press(pg, "ArrowUp");
    ok(await activeIsNth(pg, '#root button[aria-expanded]', 0), "ArrowUp moved trigger focus (must be a no-op on the horizontal axis)");
  } },
  // Tabs — MANUAL activation (activationMode="manual", tabs.tsx:61,192-202). Arrow keys move
  // the roving focus WITHOUT changing selection; only Enter/Space on the focused trigger
  // activates it. Seed: defaultValue="account" (tab[0] selected). The id `tabsmanual` is a
  // SEPARATE story so the automatic-mode `tabs` golden stays byte-identical.
  { id: "tabsmanual", state: "manual", apg: "tabs", name: "manual mode: ArrowRight moves focus but does NOT activate (selection unchanged)", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    ok((await attrOf(pg, '[role="tab"]', 0, "aria-selected")) === "true", "tab[0] must be selected at rest");
    await press(pg, "Tab"); // into the tablist, onto the selected tab
    ok(await activeIsNth(pg, '[role="tab"]', 0), "Tab did not focus the selected tab");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, '[role="tab"]', 1), "ArrowRight did not move focus to the next tab");
    ok((await attrOf(pg, '[role="tab"]', 1, "aria-selected")) === "false", "manual mode must NOT activate the focused tab on arrow");
    ok((await attrOf(pg, '[role="tab"]', 0, "aria-selected")) === "true", "the originally selected tab must stay selected in manual mode");
    const stillHidden = await pg.evaluate(() => { const t = document.querySelectorAll('[role="tab"]')[1]; const p = document.getElementById(t.getAttribute("aria-controls")); return p && p.hasAttribute("hidden"); });
    ok(stillHidden, "manual mode: the focused (not activated) tab's panel must stay hidden");
  }},
  { id: "tabsmanual", state: "manual", apg: "tabs", name: "manual mode: Enter on the focused trigger activates it (and shows its panel)", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    await press(pg, "Tab");
    await press(pg, "ArrowRight"); // focus tab[1], NOT selected yet (manual)
    ok(await activeIsNth(pg, '[role="tab"]', 1), "ArrowRight did not move focus to tab[1]");
    await press(pg, "Enter"); // activate
    await attrEq(pg, '[role="tab"]', 1, "aria-selected", "true", "Enter did not activate the focused tab in manual mode");
    ok((await attrOf(pg, '[role="tab"]', 0, "aria-selected")) === "false", "the previously selected tab must deselect after Enter");
    const shown = await pg.evaluate(() => { const t = document.querySelectorAll('[role="tab"]')[1]; const p = document.getElementById(t.getAttribute("aria-controls")); return p && !p.hasAttribute("hidden"); });
    ok(shown, "Enter did not show the newly activated tab's panel");
  }},
  { id: "tabsmanual", state: "manual", apg: "tabs", name: "manual mode: Space also activates the focused trigger", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    await press(pg, "Tab");
    await press(pg, "End"); // focus last, not selected (manual)
    ok(await activeIsNth(pg, '[role="tab"]', 2), "End did not move focus to the last tab");
    ok((await attrOf(pg, '[role="tab"]', 2, "aria-selected")) === "false", "End must not activate in manual mode");
    await press(pg, "Space");
    await attrEq(pg, '[role="tab"]', 2, "aria-selected", "true", "Space did not activate the focused tab in manual mode");
  }},

  // ToggleGroup — group-level disabled (Root `disabled` ORs into every item). EVERY item is
  // a disabled button (non-focusable / non-togglable); the group cannot be entered or toggled.
  { id: "togglegroupdisabled", state: "disabled", apg: "toolbar", name: "group disabled: every item is a disabled button, none focusable", run: async (pg) => {
    await pg.locator('[role="radio"]').first().waitFor();
    const items = pg.locator('[role="radio"]');
    ok((await items.count()) === 3, "expected 3 items");
    for (let i = 0; i < 3; i++) {
      ok((await attrOf(pg, '[role="radio"]', i, "disabled")) !== null || await items.nth(i).isDisabled(), `item ${i} must be disabled`);
    }
    // clicking a disabled item must not change the pressed item (b stays checked)
    await attrEq(pg, '[role="radio"]', 1, "aria-checked", "true", "the seeded item must stay checked");
    await items.nth(0).click({ force: true }).catch(() => {});
    await attrEq(pg, '[role="radio"]', 0, "aria-checked", "false", "a disabled item must not become checked on click");
    await attrEq(pg, '[role="radio"]', 1, "aria-checked", "true", "the seeded item must remain checked after a disabled-item click");
  }},

  // ToggleGroup — loop={false}: arrow navigation CLAMPS at the ends (no wrap). Seed value="a"
  // (item[0] is the tab stop). ArrowLeft at the first item stays on it; from the last,
  // ArrowRight stays on the last.
  { id: "togglegroupnoloop", state: "noloop", apg: "toolbar", name: "loop=false: ArrowLeft at the first item does NOT wrap to the last", run: async (pg) => {
    const sel = '[role="radio"]';
    await pg.locator(sel).first().waitFor();
    await press(pg, "Tab"); // enter, onto item[0] (seeded a)
    ok(await activeIsNth(pg, sel, 0), "Tab did not focus the first item");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 0), "loop=false: ArrowLeft at the first item must clamp (not wrap to last)");
    await press(pg, "End"); // jump to last
    ok(await activeIsNth(pg, sel, 2), "End did not focus the last item");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 2), "loop=false: ArrowRight at the last item must clamp (not wrap to first)");
  }},

  // ToggleGroup — orientation="vertical": ArrowDown/ArrowUp navigate, ArrowLeft/ArrowRight
  // inert. RovingFocusGroup stamps data-orientation=vertical on the root.
  { id: "togglegroupvert", state: "vertical", apg: "toolbar", name: "vertical: ArrowDown navigates, ArrowRight is inert", run: async (pg) => {
    const sel = '[role="radio"]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, '[role="group"]', 0, "data-orientation")) === "vertical", "root must carry data-orientation=vertical");
    await press(pg, "Tab"); // onto item[0]
    ok(await activeIsNth(pg, sel, 0), "Tab did not focus the first item");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "vertical: ArrowRight must be inert");
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, sel, 1), "vertical: ArrowDown must move to the next item");
    await press(pg, "ArrowUp");
    ok(await activeIsNth(pg, sel, 0), "vertical: ArrowUp must move to the previous item");
  }},

  // ToggleGroup — arrow navigation IGNORES modifier keys (meta/ctrl/alt/shift). Upstream
  // RovingFocusGroup returns early when any modifier is held (roving-focus-group onKeyDown).
  { id: "togglegroupnoloop", state: "noloop", apg: "toolbar", name: "Ctrl+ArrowRight does NOT navigate (modifier keys ignored)", run: async (pg) => {
    const sel = '[role="radio"]';
    await pg.locator(sel).first().waitFor();
    await press(pg, "Tab");
    ok(await activeIsNth(pg, sel, 0), "Tab did not focus the first item");
    await pg.keyboard.down("Control");
    await pg.keyboard.press("ArrowRight");
    await pg.keyboard.up("Control");
    ok(await activeIsNth(pg, sel, 0), "Ctrl+ArrowRight must NOT move focus (modifiers ignored)");
  }},

  // Accordion — type="single" NON-collapsible: clicking the OPEN trigger does NOT close it
  // (accordion.tsx the open trigger is aria-disabled). The `single` story opens item-1 at
  // mount; clicking it leaves it open + aria-expanded=true.
  { id: "accordion", state: "single", apg: "accordion", name: "single non-collapsible: clicking the open trigger does NOT close it", run: async (pg) => {
    const t0 = pg.locator('#root button[aria-expanded]').first();
    await t0.waitFor();
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "true", "item-1 must be open at mount");
    ok((await attrOf(pg, '#root button[aria-expanded]', 0, "aria-disabled")) === "true", "the single open trigger must be aria-disabled (cannot close)");
    await t0.click({ force: true }).catch(() => {});
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "true", "single non-collapsible: the open item must stay open after clicking its trigger");
  }},
  // Accordion — type="single" non-collapsible: clicking ANOTHER trigger swaps the single open
  // item (item-1 closes, item-2 opens) — set stays size 1.
  { id: "accordion", state: "single", apg: "accordion", name: "single: clicking another trigger swaps the single open item", run: async (pg) => {
    const all = pg.locator('#root button[aria-expanded]');
    await all.first().waitFor();
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "true", "item-1 must start open");
    await all.nth(1).click();
    await attrEq(pg, '#root button[aria-expanded]', 1, "aria-expanded", "true", "clicking item-2 must open it");
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "false", "opening item-2 must close item-1 (single)");
    const openCount = await pg.evaluate(() => [...document.querySelectorAll('#root button[aria-expanded]')].filter((b) => b.getAttribute("aria-expanded") === "true").length);
    ok(openCount === 1, "exactly one item may be open in single mode");
  }},
  // Accordion — type="single" COLLAPSIBLE: clicking the open trigger CLOSES it (empty set),
  // and the open trigger is NOT aria-disabled.
  { id: "accordioncollapsible", state: "collapsible", apg: "accordion", name: "single collapsible: clicking the open trigger closes it (open trigger NOT aria-disabled)", run: async (pg) => {
    const t0 = pg.locator('#root button[aria-expanded]').first();
    await t0.waitFor();
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "true", "item-1 must be open at mount");
    ok((await attrOf(pg, '#root button[aria-expanded]', 0, "aria-disabled")) === null, "collapsible: the open trigger must NOT be aria-disabled");
    await t0.click();
    await attrEq(pg, '#root button[aria-expanded]', 0, "aria-expanded", "false", "collapsible: clicking the open trigger must close it");
    const openCount = await pg.evaluate(() => [...document.querySelectorAll('#root button[aria-expanded]')].filter((b) => b.getAttribute("aria-expanded") === "true").length);
    ok(openCount === 0, "collapsible: closing the last open item must leave an empty open set");
  }},

  // Toolbar — PageUp focuses the FIRST item, PageDown the LAST (MAP_KEY_TO_FOCUS_INTENT maps
  // them identically to Home/End). The default story has 4 focusable items across the
  // toggle-group boundary (New, Edit, L, C).
  { id: "toolbar", state: "default", apg: "toolbar", name: "PageDown focuses the last item, PageUp the first", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    ok(await activeIsNth(pg, sel, 0), "could not focus the first toolbar item");
    await press(pg, "PageDown");
    ok(await activeIsNth(pg, sel, 3), "PageDown did not focus the last item");
    await press(pg, "PageUp");
    ok(await activeIsNth(pg, sel, 0), "PageUp did not focus the first item");
  }},
  // Toolbar — a Toolbar.Link activates on Space (native <a> ignores Space; upstream wires
  // ' '→currentTarget.click()). We can't observe a navigation here, but we CAN observe that
  // Space does not throw and the link stays focused (the click is dispatched on it). Roved to
  // the link (item index 1), Space keeps focus on it.
  { id: "toolbar", state: "default", apg: "toolbar", name: "ToolbarLink stays focused on Space (Space wired to click)", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    await press(pg, "ArrowRight"); // onto the Link (Edit, index 1)
    ok(await activeIsNth(pg, sel, 1), "ArrowRight did not rove onto the Link");
    const isLink = await pg.evaluate(() => document.activeElement?.tagName === "A");
    ok(isLink, "the roved item at index 1 must be the <a> Link");
    await press(pg, "Space");
    ok(await activeIsNth(pg, sel, 1), "the Link must remain focused after Space");
  }},

  // Toolbar — loop={false}: ArrowRight at the last item CLAMPS (no wrap), ArrowLeft at the
  // first clamps. 3-button toolbar.
  { id: "toolbarnoloop", state: "noloop", apg: "toolbar", name: "loop=false: ArrowRight at the last item does NOT wrap to the first", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    ok((await pg.locator(sel).count()) === 3, "expected 3 toolbar buttons");
    await focusFirst(pg, sel);
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 0), "loop=false: ArrowLeft at the first item must clamp");
    await press(pg, "End");
    ok(await activeIsNth(pg, sel, 2), "End did not focus the last item");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 2), "loop=false: ArrowRight at the last item must clamp (not wrap)");
  }},

  // Toolbar — ToggleGroup type="multiple": items carry aria-pressed (NOT role=radio), two can
  // be on simultaneously, each toggles independently.
  { id: "toolbarmultiple", state: "multiple", apg: "toolbar", name: "multiple toggle group: aria-pressed items, two on at once, independent toggle", run: async (pg) => {
    const items = pg.locator('[role="toolbar"] button[aria-pressed]');
    await items.first().waitFor();
    ok((await items.count()) === 3, "expected 3 aria-pressed toggle items (NOT role=radio)");
    ok((await pg.locator('[role="toolbar"] [role="radio"]').count()) === 0, "multiple mode must NOT use role=radio");
    ok((await attrOf(pg, '[role="toolbar"] button[aria-pressed]', 0, "aria-pressed")) === "true", "Bold must start pressed");
    await items.nth(1).click(); // press Italic too
    ok((await attrOf(pg, '[role="toolbar"] button[aria-pressed]', 0, "aria-pressed")) === "true", "Bold must STAY pressed (independent)");
    ok((await attrOf(pg, '[role="toolbar"] button[aria-pressed]', 1, "aria-pressed")) === "true", "Italic must become pressed");
    await items.nth(0).click(); // unpress Bold
    ok((await attrOf(pg, '[role="toolbar"] button[aria-pressed]', 0, "aria-pressed")) === "false", "Bold must unpress independently");
    ok((await attrOf(pg, '[role="toolbar"] button[aria-pressed]', 1, "aria-pressed")) === "true", "Italic must remain pressed");
  }},

  // ── Wave-D menus depth (STR-330): DropdownMenu Group/Label parts ────────────────
  // Two labelled groups (File: New/Open, Edit: Cut/Copy) with a Separator between. The
  // Labels are NON-interactive (no role=menuitem, not in the roving order); ArrowDown roves
  // the FOUR items ACROSS group boundaries, never landing on a label. Each group is a
  // role=group; the label is a plain div inside it. Keyed off role/data-highlighted only.
  { id: "dropdownmenugroup", apg: "menu", name: "two role=group wrappers; labels are NOT menuitems", run: async (pg) => {
    await triggerBtn(pg).click(); await pg.locator('[role="menu"]').waitFor();
    const groups = await pg.locator('[role="menu"] [role="group"]').count();
    ok(groups === 2, `expected 2 role=group wrappers, got ${groups}`);
    const items = await pg.locator('[role="menu"] [role="menuitem"]').count();
    ok(items === 4, `expected 4 menuitems (labels excluded), got ${items}`);
    // the Labels (#File / #Edit) must NOT be menuitems
    const labelIsMenuitem = await pg.evaluate(() =>
      [...document.querySelectorAll('[role="menu"] [role="menuitem"]')].some((e) => {
        const t = (e.textContent || "").trim();
        return t === "File" || t === "Edit";
      }));
    ok(!labelIsMenuitem, "a group Label must not be a role=menuitem");
  }},
  { id: "dropdownmenugroup", apg: "menu", name: "ArrowDown roves the 4 items ACROSS group boundaries, skipping labels", run: async (pg) => {
    await triggerBtn(pg).focus(); await pg.keyboard.press("ArrowDown");
    await pg.locator('[role="menu"]').waitFor(); await pg.waitForTimeout(120);
    await hlStarts(pg, "New");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Open");
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Cut");   // crosses into the 2nd group
    await pg.keyboard.press("ArrowDown"); await hlStarts(pg, "Copy");
  }},

  // ── Wave-D menus depth (STR-330): Select FORM integration (BubbleSelect) ────────
  // The select participates in a form: the trigger carries aria-required=true and a hidden
  // native <select> (BubbleSelect) mirrors the value for native submission. The bubble is
  // aria-hidden, tabindex=-1, required, with the selected <option> carrying `selected`.
  // The driver opens the select; keyed off the UPSTREAM combobox/listbox + select[aria-hidden].
  { id: "selectform", state: "required", apg: "listbox", name: "trigger is aria-required and a hidden required native <select> mirrors the value", run: async (pg) => {
    await pg.locator("select[aria-hidden]").first().waitFor({ state: "attached" });
    ok((await attrOf(pg, '[role="combobox"]', 0, "aria-required")) === "true", "trigger must be aria-required=true");
    const bubble = await pg.evaluate(() => {
      const s = document.querySelector("select[aria-hidden]");
      if (!s) return null;
      return {
        required: s.hasAttribute("required"),
        tabindex: s.getAttribute("tabindex"),
        name: s.getAttribute("name"),
        value: s.value,
        selectedOption: s.querySelector("option[selected]")?.getAttribute("value") ?? null,
      };
    });
    ok(bubble, "hidden native <select> (BubbleSelect) must be present");
    ok(bubble.required, "BubbleSelect must be required");
    ok(bubble.tabindex === "-1", "BubbleSelect must be tabindex=-1");
    ok(bubble.name === "fruit", `BubbleSelect name must be 'fruit', got ${bubble.name}`);
    ok(bubble.value === "apple", `BubbleSelect value must mirror the selection, got ${bubble.value}`);
    ok(bubble.selectedOption === "apple", "the selected <option> must carry `selected`");
  } },
  // ── Wave-D nav-group depth checks (STR-330) ──────────────────────────────────
  // Tooltip — ACTIVATING the trigger dismisses the tooltip. Upstream Tooltip.Trigger binds
  // onPointerDown→onClose (when open) and onClick composes onClose (tooltip.tsx:308-319): a
  // tooltip is a transient hint, so the moment the user commits to the trigger (clicks it) the
  // hint goes away. Open via FOCUS (instant-open, no delay race), then click the trigger and
  // assert role=tooltip is gone. Keyed off role=tooltip only, so the same check runs golden+port.
  { id: "tooltip", apg: "tooltip", name: "clicking the trigger dismisses an open tooltip", run: async (pg) => {
    await triggerBtn(pg).focus();
    await pg.getByRole("tooltip").waitFor({ timeout: 3000 });
    ok(await visible(pg, '[role="tooltip"]'), "tooltip did not open on focus (precondition)");
    await triggerBtn(pg).click();
    await pg.waitForTimeout(150);
    ok(!(await visible(pg, '[role="tooltip"]')), "clicking the trigger must dismiss the open tooltip");
  }},

  // NavigationMenu RTL — the horizontal FocusGroup SWAPS the roving arrow keys under dir="rtl":
  // ArrowLeft becomes "forward" (toward the logically-next trigger) and ArrowRight "backward",
  // because in RTL the visual-left direction is the reading-forward direction. Open story is
  // ?s=rtl (dir=rtl on the nav, OPEN at first paint). Two triggers (Item One / Item Two). Focus
  // the first → ArrowLeft must land on the second (RTL forward); ArrowRight returns to the
  // first; a second ArrowRight at the edge stays put (still NON-looping). Keyed off the trigger
  // bar (button[aria-expanded]) + dir=rtl on the nav, so the same check runs golden + port.
  { id: "navigationmenu", state: "rtl", apg: "disclosure", name: "RTL: ArrowLeft is forward, ArrowRight is backward (swapped, non-looping)", run: async (pg) => {
    await pg.locator('#root nav[dir="rtl"]').first().waitFor();
    const triggers = '#root button[aria-expanded]';
    await pg.locator(triggers).first().waitFor();
    await focusFirst(pg, triggers);
    ok(await activeIsNth(pg, triggers, 0), "could not focus the first trigger");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, triggers, 1), "RTL: ArrowLeft must move FORWARD to the next trigger");
    // NON-looping at the forward edge: a second ArrowLeft stays on the last.
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, triggers, 1), "RTL: ArrowLeft wrapped (FocusGroup must NOT loop)");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, triggers, 0), "RTL: ArrowRight must move BACKWARD to the previous trigger");
  } },
  // ── Wave-D roving depth (STR-330) ────────────────────────────────────────────
  // Tabs orientation="vertical": ArrowDown/ArrowUp navigate the roving focus (and, automatic
  // activation, select); ArrowLeft/ArrowRight are INERT (off-axis). aria-orientation/data-
  // orientation=vertical. (tabs.tsx:96,133,247; orientation drives the roving arrow axis.)
  { id: "tabsvert", state: "vertical", apg: "tabs", name: "vertical: ArrowDown navigates+activates the next tab; ArrowRight is inert", run: async (pg) => {
    const sel = '[role="tab"]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, '[role="tablist"]', 0, "aria-orientation")) === "vertical", "tablist must be aria-orientation=vertical");
    await press(pg, "Tab"); // onto the selected tab (Account, idx 0)
    ok(await activeIsNth(pg, sel, 0), "Tab did not focus the selected tab");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "ArrowRight must be inert in vertical orientation");
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, sel, 1), "ArrowDown did not move to the next tab (vertical axis)");
    await attrEq(pg, sel, 1, "aria-selected", "true", "ArrowDown did not activate the landed tab (automatic activation)");
  }},
  // Tabs dir="rtl": the horizontal arrows are SWAPPED — ArrowLeft moves to the NEXT tab,
  // ArrowRight to the previous (roving-focus getFocusIntent flips L/R under rtl).
  { id: "tabsrtl", state: "rtl", apg: "tabs", name: "rtl: ArrowLeft moves to the NEXT tab, ArrowRight to the previous", run: async (pg) => {
    const sel = '[role="tab"]';
    await pg.locator(sel).first().waitFor();
    await press(pg, "Tab"); // onto the selected tab (Account, idx 0)
    ok(await activeIsNth(pg, sel, 0), "Tab did not focus the selected tab");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 1), "rtl: ArrowLeft did not move to the NEXT tab");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "rtl: ArrowRight did not move to the previous tab");
  }},

  // Accordion horizontal orientation: ArrowLeft/ArrowRight rove between triggers, ArrowUp/Down
  // INERT; data-orientation=horizontal on the parts. (accordion orientation drives the axis.)
  { id: "accordionhoriz", state: "horizontal", apg: "accordion", name: "horizontal: ArrowRight roves to the next trigger; ArrowDown is inert", run: async (pg) => {
    const sel = '#root button[aria-expanded]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, sel, 0, "data-orientation")) === "horizontal", "trigger must be data-orientation=horizontal");
    await pg.locator(sel).nth(0).focus();
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, sel, 0), "ArrowDown must be inert in horizontal orientation");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 1), "ArrowRight did not rove to the next trigger (horizontal axis)");
  }},
  // Accordion vertical loop-wrap: ArrowDown on the LAST trigger wraps to the first; ArrowUp on
  // the first wraps to the last (RovingFocus loop default true).
  { id: "accordion", state: "open", apg: "accordion", name: "vertical loop: ArrowDown on the last trigger wraps to the first", run: async (pg) => {
    const sel = '#root button[aria-expanded]';
    await pg.locator(sel).first().waitFor();
    await pg.locator(sel).nth(2).focus();
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, sel, 0), "ArrowDown on the last trigger did not wrap to the first");
    await press(pg, "ArrowUp");
    ok(await activeIsNth(pg, sel, 2), "ArrowUp on the first trigger did not wrap to the last");
  }},

  // ToggleGroup loop (default true): ArrowRight on the last item wraps to the first; ArrowLeft
  // on the first wraps to the last. (The noloop story already pins the clamp; this pins wrap.)
  { id: "togglegroup", state: "pressed", apg: "toolbar", name: "loop: ArrowRight on the last item wraps to the first", run: async (pg) => {
    const sel = '[role="radio"]';
    await pg.locator(sel).first().waitFor();
    await pg.locator(sel).nth(2).focus();
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "ArrowRight on the last item did not wrap to the first");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 2), "ArrowLeft on the first item did not wrap to the last");
  }},
  // ToggleGroup native Enter activates the focused item (button activation → onPressedChange),
  // the same as Space (single-mode radio move).
  { id: "togglegroup", state: "pressed", apg: "toolbar", name: "Enter activates the focused item (single-mode radio move)", run: async (pg) => {
    const sel = '[role="radio"]';
    await pg.locator(sel).first().waitFor();
    await pg.locator(sel).nth(2).focus(); // focus the last item (Right)
    await press(pg, "Enter");
    await attrEq(pg, sel, 2, "aria-checked", "true", "Enter did not activate the focused item");
  }},
  // ToggleGroup dir="rtl": ArrowLeft roves to the NEXT (rightmost) item, ArrowRight to previous.
  { id: "togglegrouprtl", state: "rtl", apg: "toolbar", name: "rtl: ArrowLeft roves to the NEXT item, ArrowRight to the previous", run: async (pg) => {
    const sel = '[role="radio"]';
    await pg.locator(sel).first().waitFor();
    await pg.locator(sel).nth(0).focus();
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 1), "rtl: ArrowLeft did not rove to the NEXT item");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "rtl: ArrowRight did not rove to the previous item");
  }},

  // Toolbar dir="rtl": ArrowLeft roves forward (to the NEXT item), ArrowRight backward.
  { id: "toolbarrtl", state: "rtl", apg: "toolbar", name: "rtl: ArrowLeft roves to the NEXT item, ArrowRight to the previous", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    await focusFirst(pg, sel);
    ok(await activeIsNth(pg, sel, 0), "could not focus the first toolbar item");
    await press(pg, "ArrowLeft");
    ok(await activeIsNth(pg, sel, 1), "rtl: ArrowLeft did not rove to the NEXT item");
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "rtl: ArrowRight did not rove to the previous item");
  }},
  // Toolbar orientation="vertical": ArrowDown/ArrowUp rove, ArrowLeft/ArrowRight INERT;
  // root + items carry data-orientation=vertical.
  { id: "toolbar", state: "vertical", apg: "toolbar", name: "vertical: ArrowDown roves to the next item; ArrowRight is inert", run: async (pg) => {
    const sel = '[role="toolbar"] [data-radix-collection-item]';
    await pg.locator(sel).first().waitFor();
    ok((await attrOf(pg, '[role="toolbar"]', 0, "data-orientation")) === "vertical", "toolbar must be data-orientation=vertical");
    await focusFirst(pg, sel);
    await press(pg, "ArrowRight");
    ok(await activeIsNth(pg, sel, 0), "ArrowRight must be inert in vertical orientation");
    await press(pg, "ArrowDown");
    ok(await activeIsNth(pg, sel, 1), "ArrowDown did not rove to the next item (vertical axis)");
  } },
  // ── Wave-D: Form reset clears derived validity ──────────────────────────────────
  // Submit the empty required Control (valueMissing Message mounts, data-invalid stamps,
  // aria-describedby links). Then click Reset: the form-reset path clears the validity, so
  // the Message unmounts and data-invalid / aria-describedby are dropped.
  // Submitting an invalid form focuses the FIRST invalid control (form.tsx:167-173). On the
  // two-field story (both empty/required), focus must land on the first field (email).
  { id: "form", state: "multi", apg: "form", name: "submitting an invalid form focuses the first invalid control", run: async (pg) => {
    await pg.locator('#root form input').first().waitFor();
    await pg.locator('#root button[type="submit"]').click();
    await pg.waitForTimeout(120);
    ok(await pg.evaluate(() => document.activeElement === document.querySelectorAll("#root form input")[0]), "submit did not focus the first invalid control");
  }},
  // a custom matcher (value==="taken") marks the field invalid + mounts its Message; other values valid.
  { id: "form", state: "custom", apg: "form", name: "a custom matcher invalidates the field and mounts its message", run: async (pg) => {
    const inp = '#root input[name="username"]';
    await pg.locator(inp).waitFor();
    await pg.locator(inp).fill("taken");
    await pg.locator(inp).blur();   // native change → custom matcher runs
    await pg.waitForTimeout(120);
    const bad = await pg.evaluate(() => { const i = document.querySelector('#root input[name="username"]'); const db = i.getAttribute("aria-describedby"); return { inv: i.getAttribute("data-invalid"), linked: !!(db && document.getElementById(db.split(" ")[0])) }; });
    ok(bad.inv === "true" && bad.linked, `custom matcher did not invalidate+link (data-invalid=${bad.inv} linked=${bad.linked})`);
    await pg.locator(inp).fill("free");
    await pg.locator(inp).blur();
    await pg.waitForTimeout(120);
    ok(await pg.evaluate(() => !document.querySelector('#root input[name="username"]').hasAttribute("data-invalid")), "a valid value must clear the custom error");
  }},
  // serverInvalid focuses its control on mount (form.tsx:382-390).
  { id: "form", state: "serverInvalid", apg: "form", name: "a serverInvalid field focuses its control on mount", run: async (pg) => {
    await pg.locator('#root input[name="email"]').waitFor();
    await pg.waitForTimeout(120);
    ok(await pg.evaluate(() => document.activeElement === document.querySelector('#root input[name="email"]')), "serverInvalid did not focus its control on mount");
  }},
  // revalidate on native `change` (form.tsx:354-363): an invalid field recovers to data-valid when
  // a valid value is entered and the control fires `change` (not just `input`).
  { id: "form", state: "validatechange", apg: "form", name: "entering a valid value revalidates on change (data-invalid → data-valid)", run: async (pg) => {
    await pg.locator('#root input[name="email"]').waitFor();
    await pg.locator('#root button[type="submit"]').click();
    await pg.locator('#root input[data-invalid="true"]').first().waitFor();
    await pg.locator('#root input[name="email"]').fill("a@b.com");
    await pg.locator('#root input[name="email"]').blur();   // fires native `change`
    await pg.waitForTimeout(120);
    const r = await pg.evaluate(() => { const i = document.querySelector('#root input[name="email"]'); return { inv: i.hasAttribute("data-invalid"), val: i.getAttribute("data-valid") }; });
    ok(!r.inv && r.val === "true", `change did not revalidate (data-invalid=${r.inv} data-valid=${r.val})`);
  }},
  { id: "form", state: "reset", apg: "form", name: "a form reset clears the field validity (Message unmounts, data-invalid drops)", run: async (pg) => {
    await pg.locator('#root form').first().waitFor();
    await pg.locator('#root button[type="submit"]').click();
    await pg.locator('#root input[data-invalid="true"]').first().waitFor();
    await pg.waitForFunction(() => {
      const i = document.querySelector('#root input[name="email"]');
      const db = i?.getAttribute("aria-describedby");
      return !!(db && db.split(" ").some((id) => document.getElementById(id)));
    }, { timeout: 4000 }).catch(() => { throw new Error("submit must link a valueMissing Message via aria-describedby"); });
    await pg.locator('#root button[type="reset"]').click();
    await pg.waitForFunction(() => {
      const i = document.querySelector('#root input[name="email"]');
      return i && !i.hasAttribute("data-invalid") && !i.hasAttribute("aria-describedby");
    }, { timeout: 4000 }).catch(() => { throw new Error("reset did not clear data-invalid / aria-describedby"); });
    ok((await pg.locator('#root input[data-invalid]').count()) === 0, "no control may carry data-invalid after reset");
  }},

  // ── Wave-D: OTP paste / autocomplete-dump fills all slots ───────────────────────
  // An input event whose value is longer than one char (paste or password-manager
  // autofill) fills every slot from the sanitized+sliced code and focuses the last
  // filled slot — radix's PASTE reducer. Drive the empty field, dump "456" into slot 0.
  { id: "otp", state: "paste", apg: "roving-tabindex", name: "a multi-char input dump fills all slots and lands on the last filled slot", run: async (pg) => {
    await pg.locator('input[data-radix-otp-input]').first().waitFor();
    await pg.locator('input[data-radix-otp-input][data-radix-index="0"]').focus();
    await pg.evaluate(() => {
      const el = document.querySelector('input[data-radix-otp-input][data-radix-index="0"]');
      const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
      setter.call(el, "456");
      el.dispatchEvent(new Event("input", { bubbles: true }));
    });
    await attrEq(pg, 'input[data-radix-otp-input]', 0, "value", "4", "paste did not fill slot 0");
    ok((await attrOf(pg, 'input[data-radix-otp-input]', 1, "value")) === "5", "paste did not fill slot 1");
    ok((await attrOf(pg, 'input[data-radix-otp-input]', 2, "value")) === "6", "paste did not fill slot 2");
    ok((await attrOf(pg, 'input[type="hidden"]', 0, "value")) === "456", "hidden input must aggregate the pasted code");
    await attrEq(pg, 'input[data-radix-otp-input]', 2, "tabindex", "0", "the last filled slot must hold the roving tab stop");
    ok(await activeIsNth(pg, 'input[data-radix-otp-input]', 2), "focus must land on the last filled slot");
  }},

  // ── Wave-D: multi-thumb / RANGE slider (APG slider pattern, per-thumb) ───────────
  // Two thumbs, each role=slider with its own valuemin/now/max + an aria-label
  // (Minimum/Maximum) naming it — radix getLabel for a 2-value slider.
  { id: "sliderrange", state: "default", apg: "slider", name: "two role=slider thumbs labelled Minimum/Maximum, each focusable", run: async (pg) => {
    const thumbs = pg.locator('[role="slider"]');
    await thumbs.first().waitFor();
    ok((await thumbs.count()) === 2, "range slider must render exactly two role=slider thumbs");
    ok((await attrOf(pg, '[role="slider"]', 0, "aria-label")) === "Minimum", "thumb 0 aria-label must be Minimum");
    ok((await attrOf(pg, '[role="slider"]', 1, "aria-label")) === "Maximum", "thumb 1 aria-label must be Maximum");
    ok((await attrOf(pg, '[role="slider"]', 0, "aria-valuenow")) === "25", "thumb 0 starts at 25");
    ok((await attrOf(pg, '[role="slider"]', 1, "aria-valuenow")) === "75", "thumb 1 starts at 75");
    ok((await attrOf(pg, '[role="slider"]', 0, "tabindex")) === "0", "thumb 0 must be focusable");
    ok((await attrOf(pg, '[role="slider"]', 1, "tabindex")) === "0", "thumb 1 must be focusable");
  }},
  // Each thumb keyboard-steps its OWN index only: ArrowRight on the lower thumb moves it,
  // leaving the upper thumb untouched; ArrowLeft on the upper thumb moves only it.
  { id: "sliderrange", state: "default", apg: "slider", name: "each thumb steps independently (ArrowRight/Left on its own index)", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    await focusFirst(pg, '[role="slider"][aria-label="Minimum"]');
    await press(pg, "ArrowRight");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", "26", "lower thumb ArrowRight did not increment by one step");
    await attrEq(pg, '[role="slider"]', 1, "aria-valuenow", "75", "upper thumb must NOT move when lower thumb is stepped");
    await pg.locator('[role="slider"][aria-label="Maximum"]').focus();
    await press(pg, "ArrowLeft");
    await attrEq(pg, '[role="slider"]', 1, "aria-valuenow", "74", "upper thumb ArrowLeft did not decrement by one step");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", "26", "lower thumb must NOT move when upper thumb is stepped");
  }},
  // Home/End target the focused thumb's index: Home on the lower thumb drives it to min(0),
  // End on the upper thumb drives it to max(100). (Single-thumb Home/End semantics, per index.)
  { id: "sliderrange", state: "default", apg: "slider", name: "Home/End drive the focused thumb to min/max", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    await pg.locator('[role="slider"][aria-label="Minimum"]').focus();
    await press(pg, "Home");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", "0", "Home did not drive the lower thumb to min");
    await pg.locator('[role="slider"][aria-label="Maximum"]').focus();
    await press(pg, "End");
    await attrEq(pg, '[role="slider"]', 1, "aria-valuenow", "100", "End did not drive the upper thumb to max");
  }},
  // Pointer-drag picks the CLOSEST thumb (radix getClosestValueIndex) and drags it. Values
  // [25,75]; a pointer-down at 40% is nearest the LOWER thumb → it jumps to ≈40 (upper stays
  // 75); dragging to 10% takes the lower to ≈10. Non-circular: --golden drags identically.
  { id: "sliderrange", state: "default", apg: "slider", name: "pointer-down picks the nearest thumb and drags it (upper unchanged)", run: async (pg) => {
    const rootEl = pg.locator(".rt-SliderRoot").first();
    await rootEl.waitFor();
    const box = await rootEl.boundingBox();
    ok(!!box, "could not measure the range slider root");
    const y = box.y + box.height / 2;
    await pg.mouse.move(box.x + box.width * 0.40, y);
    await pg.mouse.down();
    await pg.waitForTimeout(60);
    const v1 = await pg.$$eval('[role="slider"]', (els) => els.map((e) => Number(e.getAttribute("aria-valuenow"))));
    ok(Math.abs(v1[0] - 40) <= 3 && Math.abs(v1[1] - 75) <= 3, `pointer at 40% should move the lower thumb to ≈40, upper stays 75 (got ${v1})`);
    await pg.mouse.move(box.x + box.width * 0.10, y);
    await pg.waitForTimeout(60);
    const v2 = await pg.$$eval('[role="slider"]', (els) => els.map((e) => Number(e.getAttribute("aria-valuenow"))));
    ok(Math.abs(v2[0] - 10) <= 3 && Math.abs(v2[1] - 75) <= 3, `dragging to 10% should set the lower thumb ≈10 (got ${v2})`);
    await pg.mouse.up();
  }},
  // minStepsBetweenThumbs: the lower thumb (starts at 40, neighbour at 60, gap=10·step)
  // cannot step closer than 50. Drive it: ArrowRight 25× — it climbs 40→50 then the
  // constraint REJECTS every further move, parking it at exactly 50 (a no-op clamp).
  { id: "sliderrange", state: "minsteps", apg: "slider", name: "minStepsBetweenThumbs blocks the thumb at the neighbour boundary", run: async (pg) => {
    await pg.locator('[role="slider"]').first().waitFor();
    ok((await attrOf(pg, '[role="slider"]', 0, "aria-valuenow")) === "40", "lower thumb must start at 40");
    ok((await attrOf(pg, '[role="slider"]', 1, "aria-valuenow")) === "60", "upper thumb must start at 60");
    await pg.locator('[role="slider"][aria-label="Minimum"]').focus();
    for (let i = 0; i < 25; i++) await press(pg, "ArrowRight");
    await attrEq(pg, '[role="slider"]', 0, "aria-valuenow", "50", "lower thumb must park at 50 (10 steps below its neighbour)");
    ok((await attrOf(pg, '[role="slider"]', 1, "aria-valuenow")) === "60", "upper thumb must stay at 60 (untouched by the lower thumb's keys)");
  } },
  // ── Wave-D: Label onMouseDown text-selection guard (label.tsx:19-27) ─────────────
  // Not an APG keyboard pattern, but a deterministic, non-circular behavior oracle that
  // validates against the real @radix-ui/react-label golden first, then the port. The guard:
  //   plain   → a multi-click (detail>1) mousedown on the label NOT inside a control must be
  //             preventDefault-ed (suppress text selection).
  //   control → a mousedown landing inside the wrapped <input> (closest('…input…')) must
  //             RETURN EARLY → NOT preventDefault-ed.
  // We dispatch a real MouseEvent({detail:2}) and read event.defaultPrevented after React's
  // (or the port's) handler ran. A single-click (detail:1) on the plain label must ALSO be
  // left alone (the detail>1 gate) — checked inline so the oracle pins the gate.
  { id: "labelguard", state: "plain", apg: "label", name: "guard: multi-click mousedown on bare label is preventDefault-ed; single-click is not", run: async (pg) => {
    await pg.locator("label[for]").first().waitFor();
    const multi = await pg.evaluate(() => {
      const lbl = document.querySelector("label[for]");
      const ev = new MouseEvent("mousedown", { bubbles: true, cancelable: true, detail: 2 });
      lbl.dispatchEvent(ev);
      return ev.defaultPrevented;
    });
    ok(multi === true, `detail=2 mousedown on bare label must be preventDefault-ed (got ${multi})`);
    const single = await pg.evaluate(() => {
      const lbl = document.querySelector("label[for]");
      const ev = new MouseEvent("mousedown", { bubbles: true, cancelable: true, detail: 1 });
      lbl.dispatchEvent(ev);
      return ev.defaultPrevented;
    });
    ok(single === false, `detail=1 (single) mousedown must NOT be preventDefault-ed (got ${single})`);
  }},
  { id: "labelguard", state: "control", apg: "label", name: "guard: multi-click mousedown INSIDE wrapped control early-returns (NOT preventDefault-ed)", run: async (pg) => {
    await pg.locator("label[for] input").first().waitFor();
    const onInput = await pg.evaluate(() => {
      const inp = document.querySelector("label[for] input");
      const ev = new MouseEvent("mousedown", { bubbles: true, cancelable: true, detail: 2 });
      inp.dispatchEvent(ev);
      return ev.defaultPrevented;
    });
    ok(onInput === false, `detail=2 mousedown on the wrapped input must early-return (NOT preventDefault-ed; got ${onInput})`);
  }},

  // ── Wave-D: AccessibleIcon a11y contract (accessible-icon.tsx:16-26) ─────────────
  // The icon SVG itself carries aria-hidden="true" + focusable="false" (injected ONTO the
  // node, NOT a wrapper span), and a sibling VisuallyHidden span holds the label text in the
  // a11y tree. Verified against the real golden first. The svg must be hidden; the label span
  // must NOT be aria-hidden and must contain the label text (announced).
  { id: "accessibleicon", apg: "structure", name: "icon svg is aria-hidden+focusable=false; label sibling is in the a11y tree", run: async (pg) => {
    await pg.locator("svg").first().waitFor();
    const r = await pg.evaluate(() => {
      const svg = document.querySelector("#root svg");
      const label = [...document.querySelectorAll("#root span")].find((s) => /overflow|clip/.test(s.getAttribute("style") || ""));
      return {
        hidden: svg && svg.getAttribute("aria-hidden"),
        focusable: svg && svg.getAttribute("focusable"),
        labelHidden: label ? label.getAttribute("aria-hidden") : "NO-LABEL",
        labelText: label ? (label.textContent || "").trim() : null,
      };
    });
    ok(r.hidden === "true", `svg must carry aria-hidden="true" (got ${r.hidden})`);
    ok(r.focusable === "false", `svg must carry focusable="false" (got ${r.focusable})`);
    ok(r.labelHidden === null, `VisuallyHidden label must NOT be aria-hidden (in a11y tree; got ${r.labelHidden})`);
    ok(r.labelText === "Settings", `label span must announce "Settings" (got ${JSON.stringify(r.labelText)})`);
  }},

  // ── Wave-D: VisuallyHidden a11y contract (visually-hidden.tsx) ───────────────────
  // The sr-only span must remain in the a11y tree — clip/overflow hiding, NEVER aria-hidden
  // / display:none / visibility:hidden (that is its entire purpose). Verified vs the golden
  // first. The ?s=plain story renders <VisuallyHidden>required</VisuallyHidden>.
  { id: "visuallyhiddenprim", state: "plain", apg: "structure", name: "visually-hidden span stays in a11y tree (clip technique, not aria-hidden/display:none)", run: async (pg) => {
    await pg.locator('span[style*="overflow"]').first().waitFor();
    const r = await pg.evaluate(() => {
      const span = document.querySelector('#root span[style*="overflow"]');
      const st = span ? span.getAttribute("style") || "" : "";
      return {
        ariaHidden: span ? span.getAttribute("aria-hidden") : "NONE",
        text: span ? (span.textContent || "").trim() : null,
        display: /display:\s*none/.test(st),
        visibility: /visibility:\s*hidden/.test(st),
        clip: /clip:\s*rect/.test(st),
      };
    });
    ok(r.ariaHidden === null, `must NOT be aria-hidden (got ${r.ariaHidden})`);
    ok(r.display === false, "must NOT use display:none");
    ok(r.visibility === false, "must NOT use visibility:hidden");
    ok(r.clip === true, "must use the clip:rect(...) hiding technique");
    ok(r.text === "required", `content must remain present/announced (got ${JSON.stringify(r.text)})`);
  }},

  // ── Wave-D: Separator a11y-tree switch (separator.tsx:31-38) ─────────────────────
  // Semantic vertical → role=separator + aria-orientation=vertical; decorative → role=none
  // (removed from a11y tree), NO aria-orientation. data-orientation is ALWAYS present. This
  // pins the a11y switch the pixel oracle is blind to. Verified vs the golden primitive page.
  { id: "separatorprim", state: "vsem", apg: "structure", name: "vertical semantic separator: role=separator + aria-orientation=vertical + data-orientation", run: async (pg) => {
    await pg.locator("div[data-orientation]").first().waitFor({ state: "attached" });
    const r = await pg.evaluate(() => {
      const el = document.querySelector("#root div[data-orientation]");
      return { role: el.getAttribute("role"), ao: el.getAttribute("aria-orientation"), o: el.getAttribute("data-orientation") };
    });
    ok(r.role === "separator", `role must be separator (got ${r.role})`);
    ok(r.ao === "vertical", `aria-orientation must be vertical (got ${r.ao})`);
    ok(r.o === "vertical", `data-orientation must be vertical (got ${r.o})`);
  }},
  { id: "separatorprim", state: "hdec", apg: "structure", name: "decorative separator: role=none (removed from a11y tree), NO aria-orientation, data-orientation kept", run: async (pg) => {
    await pg.locator("div[data-orientation]").first().waitFor({ state: "attached" });
    const r = await pg.evaluate(() => {
      const el = document.querySelector("#root div[data-orientation]");
      return { role: el.getAttribute("role"), ao: el.getAttribute("aria-orientation"), o: el.getAttribute("data-orientation") };
    });
    ok(r.role === "none", `decorative role must be none (got ${r.role})`);
    ok(r.ao === null, `decorative must have NO aria-orientation (got ${r.ao})`);
    ok(r.o === "horizontal", `data-orientation must still be present (got ${r.o})`);
  }},

  // ── Wave-D: AspectRatio inset-override + inner-prop anatomy (aspect-ratio.tsx:19-43) ─
  // The inner div merges the caller style FIRST, then position:absolute + inset:0 LAST so the
  // inset overrides any caller position; caller class/id/data-*/aria land on the INNER div,
  // the wrapper carries data-radix-aspect-ratio-wrapper="". Verified vs the golden (?s=styled).
  { id: "aspectratioprim", state: "styled", apg: "structure", name: "aspect-ratio: wrapper marker + inner div carries caller class/id/data-*, inset override present", run: async (pg) => {
    await pg.locator("[data-radix-aspect-ratio-wrapper]").first().waitFor();
    const r = await pg.evaluate(() => {
      const wrap = document.querySelector("#root [data-radix-aspect-ratio-wrapper]");
      const inner = wrap && wrap.firstElementChild;
      const st = inner ? inner.getAttribute("style") || "" : "";
      return {
        wrapMarker: wrap ? wrap.getAttribute("data-radix-aspect-ratio-wrapper") : "NO-WRAP",
        innerId: inner ? inner.getAttribute("id") : null,
        innerClass: inner ? inner.getAttribute("class") : null,
        innerData: inner ? inner.getAttribute("data-foo") : null,
        innerAria: inner ? inner.getAttribute("aria-label") : null,
        absolute: /position:\s*absolute/.test(st),
        inset: /inset:\s*0px|top:\s*0px/.test(st),
      };
    });
    ok(r.wrapMarker === "", `wrapper must carry data-radix-aspect-ratio-wrapper="" (got ${JSON.stringify(r.wrapMarker)})`);
    ok(r.innerId === "ar-inner", `caller id must land on the INNER div (got ${r.innerId})`);
    ok((r.innerClass || "").includes("my-inner"), `caller class must land on the INNER div (got ${r.innerClass})`);
    ok(r.innerData === "bar", `caller data-foo must land on the INNER div (got ${r.innerData})`);
    ok(r.innerAria === "cover", `caller aria-label must land on the INNER div (got ${r.innerAria})`);
    ok(r.absolute === true, "inner div must be position:absolute (inset override)");
    ok(r.inset === true, "inner div must carry the inset:0 override");
  }},

  // Tabs — Enter/Space on a focused tab activate it (APG: in addition to automatic activation
  // on arrow-move, the focused tab is activatable by Enter and Space). Drive into the tablist,
  // arrow to the next tab, then activate the focused tab with the key and assert selection.
  { id: "tabs", state: "tab2", apg: "tabs", name: "Space activates the focused tab", run: async (pg) => {
    await pg.locator('[role="tab"]').first().waitFor();
    await press(pg, "Tab"); // onto the selected tab (idx 0)
    ok(await activeIsNth(pg, '[role="tab"]', 0), "Tab did not focus the selected tab");
    await press(pg, "End"); // focus+activate the last tab
    ok(await activeIsNth(pg, '[role="tab"]', 2), "End did not focus the last tab");
    await press(pg, "Home"); // back to the first
    ok(await activeIsNth(pg, '[role="tab"]', 0), "Home did not focus the first tab");
    await press(pg, "Space"); // activate the focused first tab explicitly
    await attrEq(pg, '[role="tab"]', 0, "aria-selected", "true", "Space did not keep the focused tab selected/active");
    const panel = await pg.evaluate(() => { const t = document.querySelectorAll('[role="tab"]')[0]; const p = document.getElementById(t.getAttribute("aria-controls")); return p && !p.hasAttribute("hidden"); });
    ok(panel, "the activated tab's panel must be shown");
  }},
];

// CHROMIUM_BIN overrides executablePath where the nix browser set isn't materialized
// (sandbox with a system chromium); no-op in CI (version-matched nix browsers).
const b = await chromium.launch(process.env.CHROMIUM_BIN ? { executablePath: process.env.CHROMIUM_BIN } : {});
let pass = 0, fail = 0; let lastApg = "";
for (const c of CHECKS) {
  if (ONLY.length && !ONLY.includes(c.id)) continue;
  const pg = await b.newPage({ viewport: { width: 1200, height: 800 } });
  try {
    // Overlays use the plain ?c=<id> page; the stateful non-overlay patterns (radiogroup,
    // tabs, checkbox, switch, togglegroup, segmentedcontrol) carry a `state` field so the URL
    // becomes ?c=<id>&s=<state> — on the golden the mere presence of &s selects the INTERACTIVE
    // page (the ?c=<id> at-rest page is a different seeded pixel page). The port ignores &s.
    await pg.goto(`http://127.0.0.1:${PORT}/?c=${c.id}${c.state ? "&s=" + c.state : ""}`); await pg.waitForTimeout(250);
    if (c.apg !== lastApg) { console.log(`\n  ◆ ${c.id} — APG: ${c.apg}`); lastApg = c.apg; }
    await c.run(pg);
    console.log(`  ✓ ${c.name}`); pass++;
  } catch (e) {
    console.log(`  ✗ ${c.name}\n      ${e.message}`); fail++;
  } finally { await pg.close(); }
}
await b.close(); srv.close();
console.log(`\nℵ APG conformance: ${pass} pass, ${fail} fail`);
process.exit(fail ? 1 : 0);
