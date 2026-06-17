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
