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
    // move the pointer onto the content's center — the cross-move must NOT close it.
    const box = await content.boundingBox();
    ok(!!box, "could not measure the hover-card content box");
    await pg.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await pg.waitForTimeout(150);
    ok(await visible(pg, ".rt-HoverCardContent"), "the card closed when the pointer moved onto its content (hover-card must stay open)");
    ok((await attrOf(pg, ".rt-HoverCardContent", 0, "data-state")) === "open", "the content must remain data-state=open while the pointer is over it");
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
];

const b = await chromium.launch();
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
