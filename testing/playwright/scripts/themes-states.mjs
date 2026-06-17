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

// Press Escape — the DismissableLayer/RemoveScroll close path shared by every modal/popper
// overlay (dialog, alertdialog, popover, *menu, select). Keyed off no port internals.
const escClose = (pg) => pg.keyboard.press("Escape");

// CLOSE actions (STR-335 closing oracle): given an OPEN overlay, drive it into its exit
// (data-state="closed") lifecycle. Keyed off UPSTREAM role/rt-* selectors only, so the same
// action runs against golden AND port. The closing driver pins the exit animation to 100s
// BEFORE invoking this, so the closing node lingers mounted for the snapshot.
export const CLOSE = {
  dialog: escClose,
  alertdialog: escClose,
  popover: escClose,
  dropdownmenu: escClose,
  contextmenu: escClose,
  // HoverCard hides on pointer-leave of BOTH trigger and content. Move the mouse off-anchor;
  // the rt-HoverCardContent (rt-PopperContent) then lingers mounted with data-state="closed".
  hovercard: async (pg) => { await pg.mouse.move(0, 0); await pg.mouse.move(2, 2); },
  // Toast closes via Escape on the FOCUSED toast (onEscapeKeyDown → handleClose). Focus the
  // <li> first (it is tabindex=0), then Escape. The golden story adds a 100ms exit keyframe on
  // li[data-state="closed"] so Presence keeps the li MOUNTED (data-state=closed) through the
  // pinned (100s) exit — the lingering closing node the oracle captures. Keyed off UPSTREAM
  // selectors only (the tabbable li), so the same action runs against golden AND port.
  toast: async (pg) => {
    const li = pg.locator('li[data-state="open"][data-swipe-direction]').first();
    await li.focus();
    await pg.keyboard.press("Escape");
  },
  // Collapsible closes by re-clicking its (now open) trigger → onOpenToggle(false). The golden
  // story injects a 100ms exit keyframe on the closing content (div[data-state="closed"][id])
  // so Presence keeps the content MOUNTED (data-state="closed", hidden, size-vars retained,
  // EMPTY children) through the pinned (100s) exit — the lingering closing node the oracle
  // captures. Keyed off the UPSTREAM trigger only, so the same action runs against golden AND
  // port. (Without the injected keyframe the bare unstyled content has animation-name:none and
  // unmounts synchronously, like menubar/select.)
  collapsible: async (pg) => { await root(pg).getByRole("button").first().click(); },

  // ── DELIBERATELY NO closing oracle (verified against real @radix-ui/themes) ───────────────
  // select  — Radix Select.Content does NOT wrap its content in Presence: on Escape the
  //           rt-SelectContent listbox unmounts SYNCHRONOUSLY (only the rt-SelectTrigger flips
  //           to data-state="closed"). There is no lingering data-state="closed" content node
  //           to capture, so a closing-DOM oracle would be empty. Dropped from the matrix.
  // tooltip — Radix Tooltip.Content likewise unmounts on hide (pointer-leave/blur) with no
  //           lingering data-state="closed" content node — only the trigger flips to closed.
  //           No exit lifecycle node exists to snapshot. Dropped from the matrix.
  // menubar — the BARE @radix-ui/react-menubar primitive carries NO rt-* exit CSS, so its
  //           MenubarContent has animation-name:none. Presence therefore unmounts it
  //           SYNCHRONOUSLY on Escape (verified: the role=menu node is GONE the next frame,
  //           even with animations pinned to 100s — the pin only stalls nodes that HAVE an
  //           animation). Unlike the THEMED DropdownMenu (whose rt-* content animates and so
  //           lingers), there is no closing node to capture. Dropped from the matrix, same as
  //           select/tooltip. (The OPEN/item1 oracles cover the menubar DOM contract.)
  // navigationmenu — the bare @radix-ui/react-navigation-menu primitive ships NO exit CSS, so
  //           its viewport-proxied Content (Presence present={isActive}) has animation-name:none.
  //           On value-clear (Escape / re-click) the active content node UNMOUNTS SYNCHRONOUSLY —
  //           verified empirically: the next frame the open trigger is gone (aria-expanded=true
  //           count → 0), no lingering data-state="closed" / data-motion node exists, even with
  //           animations pinned. Same call as menubar/select/tooltip — dropped from the matrix.
  //           (The closed/open DOM oracles cover the full DOM contract; the keyboard close path
  //           is the APG "Escape closes + restores focus" gate.)
};

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
    // FOCUS-open path: upstream `onFocus → onOpen → handleOpen` sets wasOpenDelayedRef=false,
    // so the stateAttribute is "instant-open" (NOT the hover path's "delayed-open"). Keyed off
    // the upstream role=tooltip + the trigger's data-state, so the same driver runs golden+port.
    focusopen: async (pg) => {
      await triggerButton(pg).focus();
      await pg.getByRole("tooltip").waitFor();
      await pg.locator('button[data-state="instant-open"]').first().waitFor();
    },
  },
  hovercard: {
    open: async (pg) => { await root(pg).getByRole("link").first().hover(); await pg.locator(".rt-HoverCardContent").waitFor(); },
    // RICH-CONTENT (?s=richcontent): the card holds a tabbable <a>; on open, upstream sets
    // tabindex=-1 on every tabbable content descendant (the card is a preview, not a focus
    // target). Hover the TRIGGER link (the first link in the prose), wait for the content, then
    // wait until the in-content link has tabindex=-1 (the getTabbableNodes effect ran). Keyed
    // off the rt-HoverCardContent + the inner anchor's tabindex, so the same driver runs
    // golden+port.
    richcontent: async (pg) => {
      await root(pg).getByRole("link").first().hover();
      await pg.locator(".rt-HoverCardContent").waitFor();
      await pg.locator('.rt-HoverCardContent a[tabindex="-1"]').first().waitFor();
    },
  },
  dropdownmenu: {
    open: async (pg) => openMenu(pg, () => triggerButton(pg).click()),
    item2: async (pg) => {
      await openMenu(pg, () => triggerButton(pg).click());
      await pg.keyboard.press("ArrowDown");
      await pg.keyboard.press("ArrowDown");
    },
    // ?s=disabled disables Duplicate. Open via ArrowDown (highlights Edit), then ArrowDown
    // SKIPS the disabled Duplicate to Archive — the snapshot pins the disabled item's
    // data-disabled/aria-disabled + tabindex=-1 and the roving tabindex distribution.
    disabled: async (pg) => {
      await triggerButton(pg).focus();
      await pg.keyboard.press("ArrowDown");
      await pg.locator('[role="menu"]').first().waitFor();
      await pg.locator('[role="menuitem"][data-highlighted]').first().waitFor();
      await pg.keyboard.press("ArrowDown");
      await pg.waitForFunction(() => {
        const hl = document.querySelector('[role="menuitem"][data-highlighted]');
        return hl && (hl.textContent || "").startsWith("Archive");
      });
    },
  },
  contextmenu: {
    open: async (pg) => openMenu(pg, () => pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" })),
    // right-click open then ArrowDown ×2 → the second enabled item (Duplicate) lands
    // data-highlighted (roving tabindex=0). Mirrors dropdownmenu.item2. Keyed off
    // role/data-* only, so the same driver runs against golden and port.
    item2: async (pg) => {
      await openMenu(pg, () => pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" }));
      await pg.keyboard.press("ArrowDown");
      await pg.keyboard.press("ArrowDown");
      await pg.waitForFunction(() => {
        const hl = document.querySelector('[role="menuitem"][data-highlighted]');
        return hl && (hl.textContent || "").startsWith("Duplicate");
      });
    },
    // ?s=disabled disables Duplicate. Open via right-click, ArrowDown highlights Edit,
    // ArrowDown SKIPS the disabled Duplicate to Delete — the snapshot pins the disabled
    // item's data-disabled/aria-disabled + tabindex=-1 and the roving tabindex distribution.
    disabled: async (pg) => {
      await openMenu(pg, () => pg.locator("#root .rt-BaseMenuTrigger, #root [data-state]").first().click({ button: "right" }));
      await pg.keyboard.press("ArrowDown");
      await pg.locator('[role="menuitem"][data-highlighted]').first().waitFor();
      await pg.keyboard.press("ArrowDown");
      await pg.waitForFunction(() => {
        const hl = document.querySelector('[role="menuitem"][data-highlighted]');
        return hl && (hl.textContent || "").startsWith("Delete");
      });
    },
  },
  menubar: {
    // Menubar is a horizontal roving bar of DropdownMenu-style menus. Open the FIRST menu
    // (File) by clicking its trigger (role=menuitem); the menus are non-modal so no scroll-lock.
    // Keyed off upstream role/data-* only, so the same driver runs against golden and port.
    open: async (pg) => openMenu(pg, () => root(pg).getByRole("menuitem").first().click()),
    // open then ArrowDown → the first menu item lands data-highlighted (roving tabindex=0).
    item1: async (pg) => {
      await openMenu(pg, () => root(pg).getByRole("menuitem").first().click());
      await pg.keyboard.press("ArrowDown");
      await pg.locator('[role="menu"] [role="menuitem"][data-highlighted]').first().waitFor();
    },
    // ?s=disabled disables "New Window" (item-2 of File). Open via ArrowDown (highlights New
    // Tab), ArrowDown SKIPS the disabled New Window to Print — the snapshot pins the disabled
    // item's data-disabled/aria-disabled + tabindex=-1 and the roving tabindex distribution.
    disabled: async (pg) => {
      await root(pg).getByRole("menuitem").first().focus();
      await pg.keyboard.press("ArrowDown");
      await pg.locator('[role="menu"] [role="menuitem"][data-highlighted]').first().waitFor();
      await pg.keyboard.press("ArrowDown");
      await pg.waitForFunction(() => {
        const hl = document.querySelector('[role="menu"] [role="menuitem"][data-highlighted]');
        return hl && (hl.textContent || "").startsWith("Print");
      });
    },
  },
  select: {
    open: async (pg) => { await pg.locator(".rt-SelectTrigger").click(); await pg.locator('[role="listbox"]').waitFor(); },
  },
  toast: {
    // Toast is rendered CONTROLLED open={true} duration={Infinity} (golden story), so it is
    // MOUNTED open at first paint — NO click, NO queue timing. The driver just waits for the
    // portaled <li> to be in the DOM. The <li> is a PLAIN <li> (NO role; the separate role=
    // status node is the SR announce mirror, normalized out — see themes-open-dom.mjs). Key
    // off the li's stable data-* (data-state=open + data-swipe-direction) inside the role=
    // region viewport, never any port-internal class, so the same driver runs golden + port.
    // The role=status announce node self-unmounts 1000ms after open (radix isAnnounced timer);
    // it is also stripped symmetrically in the normalizer, so the snapshot is stable either way.
    open: async (pg) => {
      await pg.locator('li[data-state="open"][data-swipe-direction]').first().waitFor();
    },
  },
  navigationmenu: {
    // OPEN at first paint via defaultValue="one" — NO click/hover, so the delayDuration/
    // skipDelayDuration open timers never run (the toast-like racy part is off the capture
    // path). Wait for the open trigger (aria-expanded=true), the mounted content (data-state=
    // open), the Viewport's measured size var to resolve (offsetWidth/Height via ResizeObserver
    // → rAF), AND the Indicator node ([data-state="visible"], which renders null until its
    // position is measured). Then settle() flushes the ResizeObserver rAF. Keyed off UPSTREAM
    // role/data-* selectors only, so the same driver runs against golden and port.
    open: async (pg) => {
      await root(pg).locator('button[aria-expanded="true"]').first().waitFor();
      // the active content (proxied into the viewport) — has aria-labelledby, NO data-state.
      await pg.locator('[aria-labelledby]').first().waitFor({ state: "attached" });
      // the indicator renders null until its position is measured (it's an absolutely-
      // positioned zero-flow node, so wait for ATTACHED, not visible).
      await pg.locator('[data-state="visible"]').first().waitFor({ state: "attached" });
      // the viewport sets its size var only after measuring the active content's offset dims.
      await pg.waitForFunction(() => {
        const vp = [...document.querySelectorAll('[data-state="open"]')]
          .find((e) => e.style.getPropertyValue("--radix-navigation-menu-viewport-width") !== "");
        return !!vp;
      });
    },
    // At rest: no value, the trigger is data-state=closed aria-expanded=false with NO
    // aria-controls; no content/viewport/indicator mounted. The `?s=closed` golden variant
    // omits defaultValue. No interaction — wait for the closed trigger.
    closed: async (pg) => {
      await root(pg).locator('button[aria-expanded="false"][data-state="closed"]').first().waitFor();
    },
    // VERTICAL orientation (?s=vertical): OPEN at first paint (defaultValue="one") with
    // data-orientation=vertical. Same open-state wait as `open`, plus assert the nav carries
    // data-orientation=vertical (the Indicator then measures top/height/translateY). Keyed off
    // UPSTREAM data-orientation/data-state selectors so the same driver runs golden+port.
    vertical: async (pg) => {
      await root(pg).locator('[data-orientation="vertical"]').first().waitFor();
      await root(pg).locator('button[aria-expanded="true"]').first().waitFor();
      await pg.locator('[aria-labelledby]').first().waitFor({ state: "attached" });
      await pg.locator('[data-state="visible"]').first().waitFor({ state: "attached" });
      await pg.waitForFunction(() => {
        const vp = [...document.querySelectorAll('[data-state="open"]')]
          .find((e) => e.style.getPropertyValue("--radix-navigation-menu-viewport-width") !== "");
        return !!vp;
      });
    },
    // TOGGLE-CLOSE (?s=open): open at first paint, then CLICK the open trigger → onItemSelect
    // root toggle (prevValue===itemValue ? '' : itemValue) closes it. Snapshot the post-click
    // at-rest nav (both triggers aria-expanded=false, content unmounted). Keyed off the open
    // trigger's aria-expanded=true then waiting for it to flip to false.
    clicktoggle: async (pg) => {
      const openTrig = root(pg).locator('button[aria-expanded="true"]').first();
      await openTrig.waitFor();
      await openTrig.click();
      await root(pg).locator('button[aria-expanded="false"][data-state="closed"]').first().waitFor();
      await pg.waitForFunction(() => document.querySelectorAll('button[aria-expanded="true"]').length === 0);
    },
  },

  // ── Interactive (stateful, non-overlay) components ──────────────────────────────
  // Driven into a single post-interaction state, keyed off UPSTREAM role/class/data-state
  // selectors only (never port-internal classes) so the same driver runs against golden
  // and port. These have no `open` state — themes-a11y guards on STATES[id].open.
  accordion: {
    open: async (pg) => {
      const trig = root(pg).locator('button[aria-expanded]').first();
      await trig.click();
      await pg.locator('[role="region"][data-state="open"]:not([hidden])').first().waitFor();
    },
    // ?s=single: type=single NON-collapsible, item-1 OPEN at first paint. STATELESS — wait for
    // the open region AND the aria-disabled=true open trigger (the un-closable single open item).
    single: async (pg) => {
      await pg.locator('[role="region"][data-state="open"]:not([hidden])').first().waitFor();
      await root(pg).locator('button[aria-expanded="true"][aria-disabled="true"]').first().waitFor();
    },
    // ?s=multiple (the default type): open TWO items (item-1 then item-3) and assert BOTH
    // regions are open simultaneously (independent toggles, set semantics). Keyed off upstream
    // aria-expanded/role=region only, so the same driver runs against golden and port.
    multiple: async (pg) => {
      const trigs = root(pg).locator('button[aria-expanded]');
      await trigs.nth(0).click();
      await trigs.nth(2).click();
      await pg.waitForFunction(() => {
        const open = [...document.querySelectorAll('[role="region"][data-state="open"]')].filter((e) => !e.hasAttribute("hidden"));
        return open.length === 2;
      });
    },
  },
  collapsible: {
    open: async (pg) => {
      await triggerButton(pg).click();
      await pg.locator('[data-state="open"]:not([hidden])').first().waitFor();
    },
    // `?s=disabled` renders the Root disabled — NO interaction. The at-rest CLOSED DOM is the
    // oracle: root+trigger carry data-disabled="" and the trigger the `disabled` attr (the
    // content is absent while closed). Keyed off the UPSTREAM disabled+closed trigger only, so
    // the same driver runs against golden and port.
    disabled: async (pg) => {
      await root(pg).locator('button[disabled][data-state="closed"]').first().waitFor();
    },
  },
  tabs: {
    tab2: async (pg) => {
      const tabs = root(pg).getByRole("tab");
      await tabs.nth(1).click();
      await pg.locator('[role="tabpanel"]:not([hidden])').first().waitFor();
      await pg.waitForFunction(() => {
        const t = document.querySelectorAll('[role="tab"]')[1];
        return t && t.getAttribute("data-state") === "active";
      });
    },
  },
  radiogroup: {
    checked: async (pg) => {
      const target = pg.locator('[role="radio"][value="2"]').first();
      await target.waitFor();
      await target.click();
      await pg.locator('[role="radio"][value="2"][data-state="checked"]').first().waitFor();
      await pg.locator('[role="radio"][value="1"][data-state="unchecked"]').first().waitFor();
    },
    // ?s=keys / ?s=mixed seed — at-rest 3-item group, middle item disabled (data-disabled='').
    // value=1 checked, value=2 disabled+unchecked, value=3 enabled+unchecked.
    keys: async (pg) => {
      await pg.locator('[role="radio"][value="1"][data-state="checked"]').first().waitFor();
      await pg.locator('[role="radio"][value="2"][data-disabled][disabled]').first().waitFor();
      await pg.locator('[role="radio"][value="3"][data-state="unchecked"]').first().waitFor();
    },
    mixed: async (pg) => {
      await pg.locator('[role="radio"][value="1"][data-state="checked"]').first().waitFor();
      await pg.locator('[role="radio"][value="2"][data-disabled][disabled]').first().waitFor();
      await pg.locator('[role="radio"][value="3"][data-state="unchecked"]').first().waitFor();
    },
    // ?s=disabledgroup seed — whole group disabled: root + every item data-disabled=''.
    disabledgroup: async (pg) => {
      await pg.locator('[role="radiogroup"][data-disabled]').first().waitFor();
      await pg.locator('[role="radio"][value="1"][data-disabled][disabled]').first().waitFor();
      await pg.locator('[role="radio"][value="2"][data-disabled][disabled]').first().waitFor();
    },
    // ?s=horizontal seed — explicit horizontal orientation on root + items.
    horizontal: async (pg) => {
      await pg.locator('[role="radiogroup"][aria-orientation="horizontal"][data-orientation="horizontal"]').first().waitFor();
      await pg.locator('[role="radio"][value="1"][data-orientation="horizontal"]').first().waitFor();
    },
  },
  checkbox: {
    checked: async (pg) => {
      const cb = root(pg).getByRole("checkbox").first();
      await cb.waitFor();
      await cb.click();
      await root(pg).locator('[role="checkbox"][data-state="checked"]').first().waitFor();
    },
    // ?s=indeterminate seed — at rest the checkbox is mixed (aria-checked=mixed, indicator shown).
    indeterminate: async (pg) => {
      await root(pg).locator('[role="checkbox"][aria-checked="mixed"][data-state="indeterminate"]').first().waitFor();
    },
    // ?s=disabled seed — at rest a checked + disabled checkbox (data-disabled='' on root).
    disabled: async (pg) => {
      await root(pg).locator('[role="checkbox"][data-state="checked"][data-disabled][disabled]').first().waitFor();
    },
  },
  switch: {
    on: async (pg) => {
      const sw = root(pg).locator('button.rt-SwitchRoot[role="switch"]').first();
      await sw.waitFor();
      await sw.click();
      await root(pg).locator('button.rt-SwitchRoot[data-state="checked"]').first().waitFor();
    },
    // at-rest, off — no click. Locks the unchecked root+thumb surface.
    rest: async (pg) => {
      await root(pg).locator('button.rt-SwitchRoot[role="switch"][data-state="unchecked"]').first().waitFor();
    },
    // ?s=disabled seed — disabled off switch (data-disabled='' on root + thumb).
    disabled: async (pg) => {
      await root(pg).locator('button.rt-SwitchRoot[data-state="unchecked"][data-disabled][disabled]').first().waitFor();
    },
    // ?s=required seed — aria-required=true on the switch button (documents the divergence:
    // port emits aria-required only when required; upstream always emits it).
    required: async (pg) => {
      await root(pg).locator('button.rt-SwitchRoot[role="switch"][aria-required="true"]').first().waitFor();
    },
  },
  toggle: {
    pressed: async (pg) => {
      const btn = root(pg).locator('button[aria-pressed]').first();
      await btn.waitFor();
      await btn.click();
      await pg.locator('button[aria-pressed="true"][data-state="on"]').first().waitFor();
    },
    // at-rest, unpressed — no click. Locks the off half of the aria-pressed/data-state contract.
    rest: async (pg) => {
      await root(pg).locator('button[aria-pressed="false"][data-state="off"]').first().waitFor();
    },
    // ?s=disabled seed — assert the disabled toggle renders disabled + data-disabled='' at rest.
    disabled: async (pg) => {
      await root(pg).locator('button[aria-pressed="false"][data-state="off"][data-disabled][disabled]').first().waitFor();
    },
  },
  togglegroup: {
    // Single-mode bare ToggleGroup renders the root as role=group (NOT radiogroup) with
    // role=radio items. Click the FIRST item ("Left") so exactly one lands data-state=on /
    // aria-checked=true, away from the defaultValue="b" seed.
    pressed: async (pg) => {
      const first = root(pg).locator('[role="radio"]').first();
      await first.waitFor();
      await first.click();
      await root(pg).locator('[role="radio"][data-state="on"][aria-checked="true"]').first().waitFor();
      await pg.waitForFunction(() => {
        const r = [...document.querySelectorAll('[role="radio"]')];
        return r.length === 3 && r[0].getAttribute("data-state") === "on"
          && r[1].getAttribute("data-state") === "off";
      });
    },
    // multiple-mode (?s=multiple): TWO items pressed at first paint (defaultValue=[a,c]).
    // Items keep aria-pressed (NOT role=radio/aria-checked); root role=group. STATELESS —
    // just wait for the two pressed items so the at-rest multi-select DOM is the oracle.
    multiple: async (pg) => {
      await root(pg).locator('button[aria-pressed]').first().waitFor();
      await pg.waitForFunction(() => {
        const b = [...document.querySelectorAll('button[aria-pressed]')];
        return b.length === 3 && b[0].getAttribute("aria-pressed") === "true"
          && b[1].getAttribute("aria-pressed") === "false"
          && b[2].getAttribute("aria-pressed") === "true"
          && !document.querySelector('[role="radio"]');
      });
    },
  },
  segmentedcontrol: {
    selected: async (pg) => {
      const items = pg.locator(".rt-SegmentedControlRoot button.rt-SegmentedControlItem");
      await items.nth(1).waitFor();
      await items.nth(1).click();
      await pg.locator('button.rt-SegmentedControlItem[data-state="on"]').nth(0).waitFor();
      await pg.waitForFunction(() => {
        const btns = [...document.querySelectorAll("button.rt-SegmentedControlItem")];
        return btns.length === 3 && btns[1].getAttribute("data-state") === "on"
          && btns[0].getAttribute("data-state") === "off";
      });
    },
  },
  checkboxgroup: {
    checked: async (pg) => {
      const item = pg.locator('.rt-CheckboxGroupItemCheckbox[data-state="unchecked"]').first();
      await item.waitFor();
      await item.click();
      await pg.locator('.rt-CheckboxGroupItemCheckbox[data-state="checked"]').first().waitFor();
    },
  },
  radiocards: {
    selected: async (pg) => {
      const items = pg.locator('#root [role="radio"].rt-RadioCardsItem');
      await items.nth(1).waitFor();
      await items.nth(1).click();
      await pg.locator('#root [role="radio"].rt-RadioCardsItem[data-state="checked"][aria-checked="true"][value="2"]').waitFor();
      await pg.locator('#root [role="radio"].rt-RadioCardsItem[data-state="unchecked"][value="1"]').waitFor();
    },
  },
  checkboxcards: {
    selected: async (pg) => {
      const card = pg.locator('label.rt-CheckboxCardsItem').first();
      await card.waitFor();
      await card.click();
      await pg.locator('button.rt-CheckboxCardCheckbox[data-state="checked"]').first().waitFor();
    },
  },
  tabnav: {
    active: async (pg) => {
      await pg.locator('a.rt-TabNavLink[data-active]').first().waitFor();
      await pg.locator('a.rt-TabNavLink[aria-current="page"]').first().waitFor();
    },
  },
  accessibleicon: {
    // STATELESS: the svg carries aria-hidden="true"+focusable="false" (injected ONTO the
    // icon, not a wrapper), followed by a VisuallyHidden label span. `shown` just waits for
    // the hidden svg; rest and shown snapshot the SAME static DOM.
    shown: async (pg) => {
      await pg.locator('svg[aria-hidden="true"]').first().waitFor({ state: "attached" });
    },
  },
  avatar: {
    // Fallback-only avatar — STATELESS. No src ⇒ Radix reports 'error' immediately ⇒ the
    // at-rest DOM is the fallback branch (rt-AvatarFallback span, NO <img>). The `fallback`
    // state waits for the fallback span and asserts the <img> is ABSENT (the load-strategy
    // contract: the real img is never in the DOM unless loaded). Keyed off the UPSTREAM
    // rt-AvatarFallback class only, so the same driver runs against golden and port.
    fallback: async (pg) => {
      await root(pg).locator('.rt-AvatarFallback').first().waitFor();
      await pg.waitForFunction(() => document.querySelector('#root img') === null);
    },
  },
  progress: {
    // Determinate progress bar — STATELESS (no interaction). The `shown` state just
    // waits for the role=progressbar to be laid out; rest and shown snapshot the SAME
    // static DOM. The oracle pins the integer-formatted aria-valuenow/data-value + the
    // aria-valuetext + the data-state/value/max wiring on root AND indicator.
    shown: async (pg) => {
      await pg.locator('[role="progressbar"]').first().waitFor();
      await pg.waitForFunction(() =>
        document.querySelector('[role="progressbar"]')?.getAttribute("aria-valuenow") === "25");
    },
    // `?s=indeterminate` — no value: data-state=indeterminate, NO aria-valuenow/data-value.
    indeterminate: async (pg) => {
      await pg.locator('[role="progressbar"][data-state="indeterminate"]').first().waitFor();
      await pg.waitForFunction(() =>
        document.querySelector('[role="progressbar"]')?.getAttribute("aria-valuenow") === null);
    },
    // `?s=complete` — value===max: data-state=complete (strict equality).
    complete: async (pg) => {
      await pg.locator('[role="progressbar"][data-state="complete"]').first().waitFor();
      await pg.waitForFunction(() =>
        document.querySelector('[role="progressbar"]')?.getAttribute("aria-valuenow") === "100");
    },
    // `?s=custommax` — max=200,value=50: aria-valuemax=200, aria-valuetext=25%, data-max=200.
    custommax: async (pg) => {
      await pg.locator('[role="progressbar"][aria-valuemax="200"]').first().waitFor();
      await pg.waitForFunction(() =>
        document.querySelector('[role="progressbar"]')?.getAttribute("aria-valuetext") === "25%");
    },
  },
  scrollarea: {
    // type="always" renders the scrollbar at rest — no click/hover/scroll needed. The
    // testable value is the SCROLLBAR + THUMB anatomy, deterministic because `always`
    // mounts the scrollbar unconditionally and the fixed 120px box overflows vertically.
    // Wait (keyed off UPSTREAM selectors) for the vertical scrollbar AND its thumb to be
    // laid out + sized (hasThumb requires a measured viewport/content ratio), so the
    // post-measure DOM has settled before the snapshot.
    shown: async (pg) => {
      await pg.locator('.rt-ScrollAreaScrollbar[data-orientation="vertical"][data-state="visible"]').first().waitFor();
      await pg.locator('.rt-ScrollAreaThumb[data-state="visible"]').first().waitFor();
      await pg.waitForFunction(() => {
        const t = document.querySelector('.rt-ScrollAreaThumb');
        // thumb must be measured: its height var resolves to a non-zero px (ratio applied).
        return t && t.getBoundingClientRect().height > 1;
      });
    },
  },
  slider: {
    // Single-thumb slider (role=slider, defaultValue=[40], min 0 max 100 step 1). Drive it
    // purely by KEYBOARD: focus the thumb, press ArrowRight 5× → a deterministic value of 45
    // (40 + 5·step). The landed value is exact, so the thumb's `left: calc(45% + …)` and the
    // range's `right: 55%` percentages (which the normalizer does NOT touch) are stable.
    stepped: async (pg) => {
      const thumb = root(pg).locator('[role="slider"]').first();
      await thumb.waitFor();
      await thumb.focus();
      for (let i = 0; i < 5; i++) await pg.keyboard.press("ArrowRight");
      await pg.waitForFunction(() =>
        document.querySelector('[role="slider"]')?.getAttribute("aria-valuenow") === "45");
    },
    // At-rest single-thumb DOM (no interaction): defaultValue=40 → aria-valuenow=40, range
    // right:60%, thumb left:calc(40% + <px>). Pins the initial-render geometry + defaultValue
    // passthrough at the DOM level (the stepped oracle only proves the post-keyboard state).
    rest: async (pg) => {
      const thumb = root(pg).locator('[role="slider"]').first();
      await thumb.waitFor();
      await pg.waitForFunction(() =>
        document.querySelector('[role="slider"]')?.getAttribute("aria-valuenow") === "40");
    },
    // `?s=disabled` → aria-disabled on root + data-disabled='' on root/track/range/thumb, and
    // the thumb's tabindex is dropped (non-focusable). No interaction; the at-rest DOM is the oracle.
    disabled: async (pg) => {
      await root(pg).locator('[aria-disabled="true"]').first().waitFor();
      await pg.locator('[role="slider"][data-disabled]').first().waitFor();
      await pg.waitForFunction(() =>
        !document.querySelector('[role="slider"]')?.hasAttribute("tabindex"));
    },
  },

  // ── Bare @radix-ui/react-* primitives (toolbar / passwordtoggle / otp / form) ─────────
  // Radix Themes ships no component for these; the golden renders the genuine upstream
  // primitive unstyled. Drivers key ONLY off upstream role/data-*/aria/type selectors so the
  // same driver runs against golden and port. No overlay → no CLOSE-table entry for any of them.
  toolbar: {
    // APG Toolbar (https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/). At rest (before focus enters)
    // RovingFocusGroup carries tabindex=0 on the toolbar ROOT and -1 on every item; the tabindex=0
    // migrates onto an item only once focus enters (the `roved` state proves that). The at-rest DOM
    // is fully deterministic — wait for the toolbar root + its (-1) items to be laid out.
    default: async (pg) => {
      await root(pg).locator('[role="toolbar"][tabindex="0"]').first().waitFor();
      await pg.locator('[role="toolbar"] > button').first().waitFor();
    },
    // `?s=vertical` golden variant → orientation flip (aria-orientation/data-orientation=vertical).
    vertical: async (pg) => {
      await root(pg).locator('[role="toolbar"][aria-orientation="vertical"]').first().waitFor();
      await pg.locator('[role="toolbar"] > button').first().waitFor();
    },
    // ArrowRight rotates the roving tabindex=0 from item 0 → item 1 (deterministic: focus + keydown
    // are synchronous). Keyed off the focusable toolbar items (those carrying a tabindex attr).
    roved: async (pg) => {
      const items = root(pg).locator('[role="toolbar"] > *[tabindex]');
      await items.first().waitFor();
      await items.first().focus();
      await pg.keyboard.press("ArrowRight");
      await pg.waitForFunction(() => {
        const it = [...document.querySelectorAll('[role="toolbar"] > *')].filter((e) => e.hasAttribute("tabindex"));
        return it[1]?.getAttribute("tabindex") === "0" && it[0]?.getAttribute("tabindex") === "-1";
      });
    },
    // `?s=disabled` golden variant → the first BUTTON (New) carries the native disabled attr
    // and is excluded from the roving order (RovingFocusGroup.Item focusable={!disabled}).
    // STATELESS at-rest — wait for the disabled button to be laid out.
    disabled: async (pg) => {
      await root(pg).locator('[role="toolbar"][tabindex="0"]').first().waitFor();
      await pg.locator('[role="toolbar"] > button[disabled]').first().waitFor();
    },
  },
  passwordtoggle: {
    // At rest: input type=password (the load-bearing state signal). No interaction.
    hidden: async (pg) => {
      await root(pg).locator("input").first().waitFor();
      await pg.locator('input[type="password"]').first().waitFor();
    },
    // Click the toggle → flushSync flips type=password→text and Slot text Show→Hide synchronously.
    visible: async (pg) => {
      const btn = root(pg).getByRole("button").first();
      await btn.waitFor();
      await btn.click();
      await pg.locator('input[type="text"]').first().waitFor();
      await pg.waitForFunction(() => document.querySelector("button")?.textContent?.trim() === "Hide");
    },
  },
  otp: {
    // defaultValue="123" 3-slot at rest: inputs carry value 1/2/3, hidden input value=123, roving
    // tabstop = clamp(len,0,size-1). No interaction; the at-rest DOM is the oracle.
    filled: async (pg) => {
      await root(pg).locator('[role="group"]').first().waitFor();
      await pg.locator('input[data-radix-otp-input][data-radix-index="2"]').waitFor();
      await pg.waitForFunction(() => document.querySelector('input[type="hidden"]')?.value === "123");
    },
    // `?s=empty` golden variant → no defaultValue: every slot empty, hidden input empty. (At rest,
    // before focus enters, RovingFocusGroup carries tabindex=-1 on every input; tabindex=0 migrates
    // onto a slot only on focus — the `typed` state proves that. The at-rest DOM is deterministic.)
    empty: async (pg) => {
      await root(pg).locator('[role="group"]').first().waitFor();
      await pg.locator('input[data-radix-otp-input][data-radix-index="2"]').waitFor();
      await pg.waitForFunction(() => {
        const a = [...document.querySelectorAll("input[data-radix-otp-input]")];
        return a.length === 3 && a.every((i) => i.value === "")
          && document.querySelector('input[type="hidden"]')?.value === "";
      });
    },
    // Type "45" into the empty story → inputs[0]=4 inputs[1]=5, roving tabstop advanced to index 2
    // (deterministic: value-driven, no timing). Drive against `?s=empty` (see capture matrix).
    typed: async (pg) => {
      const first = root(pg).locator('input[data-radix-otp-input][data-radix-index="0"]');
      await first.waitFor();
      await first.focus();
      await pg.keyboard.type("45");
      await pg.waitForFunction(() => {
        const a = [...document.querySelectorAll("input[data-radix-otp-input]")];
        return a[0].value === "4" && a[1].value === "5" && a[2].getAttribute("tabindex") === "0";
      });
    },
    // `?s=alpha` golden variant → validationType="alpha": every slot inputmode=text +
    // pattern=[a-zA-Z]{1}, defaultValue "abc". No interaction; the at-rest DOM is the oracle.
    alpha: async (pg) => {
      await root(pg).locator('[role="group"]').first().waitFor();
      await pg.locator('input[data-radix-otp-input][data-radix-index="2"]').waitFor();
      await pg.waitForFunction(() => {
        const a = [...document.querySelectorAll("input[data-radix-otp-input]")];
        return a.length === 3 && a.every((i) => i.getAttribute("pattern") === "[a-zA-Z]{1}" && i.getAttribute("inputmode") === "text")
          && document.querySelector('input[type="hidden"]')?.value === "abc";
      });
    },
  },
  form: {
    // serverInvalid is a PURE PROP (no event, no async): field/label/control carry data-invalid=true
    // and the control carries aria-invalid=true. NOTE — a bare match="valueMissing" Message does NOT
    // render here (validity.valueMissing is false; serverInvalid is a separate flag), so there is no
    // aria-describedby on this path; the Message+describedby anatomy is the `forceMatch` state's job.
    // This state's distinct contract is the data-invalid/aria-invalid stamping.
    serverInvalid: async (pg) => {
      await root(pg).locator('input[aria-invalid="true"][data-invalid="true"]').first().waitFor();
      await pg.locator('label[data-invalid]').first().waitFor();
    },
    // forceMatch renders the Message unconditionally on first paint (no event) → proves the <span id>
    // anatomy + aria-describedby registration. data-invalid is NOT set (validity still valid).
    forceMatch: async (pg) => {
      await root(pg).locator("form").first().waitFor();
      await pg.waitForFunction(() => {
        const i = document.querySelector('input[name="email"]');
        const db = i?.getAttribute("aria-describedby");
        return !!(db && db.split(" ").some((id) => document.getElementById(id)));
      });
    },
    // At rest: no data-valid/invalid anywhere, control has title="" + id + name, NO aria-describedby,
    // NO Message span. Just wait for the control to be present (no interaction).
    "rest-valid": async (pg) => {
      await root(pg).locator('input[name="email"]').first().waitFor();
      await pg.waitForFunction(() => {
        const i = document.querySelector('input[name="email"]');
        return i && !i.hasAttribute("aria-describedby") && !i.hasAttribute("data-invalid");
      });
    },
    // Event-gated: press Submit on the required-empty Control → native `invalid` fires → the
    // valueMissing Message mounts and registers into aria-describedby. Capture ONLY after the
    // aria-describedby link RESOLVES (message id present AND getElementById exists), never a timeout.
    valueMissing: async (pg) => {
      await root(pg).locator('button[type="submit"]').click();
      await pg.locator('input[data-invalid="true"]').first().waitFor();
      await pg.waitForFunction(() => {
        const i = document.querySelector('input[name="email"]');
        const db = i?.getAttribute("aria-describedby");
        return !!(db && db.split(" ").some((id) => document.getElementById(id)));
      });
    },
    // Event-gated TYPE-mismatch: type a non-email into the required email Control + submit →
    // native validity.typeMismatch=true (NOT valueMissing) → the TypeMismatch Message
    // ("Provide a valid email") mounts and registers into aria-describedby. Proves the field
    // reads the LIVE ValidityState, not just valueMissing. Wait for the typeMismatch message
    // span to exist AND be linked, never a timeout.
    typeMismatch: async (pg) => {
      const email = root(pg).locator('input[name="email"]');
      await email.fill("abc");
      await root(pg).locator('button[type="submit"]').click();
      await pg.locator('input[data-invalid="true"]').first().waitFor();
      await pg.waitForFunction(() => {
        const i = document.querySelector('input[name="email"]');
        const db = i?.getAttribute("aria-describedby");
        if (!(db && db.split(" ").some((id) => document.getElementById(id)))) return false;
        // the TypeMismatch message text must be present among the described-by targets.
        return db.split(" ").some((id) => (document.getElementById(id)?.textContent || "").includes("valid email"));
      });
    },
    // `?s=multiMessage` forceMatches BOTH messages on first paint → aria-describedby lists TWO
    // ids, space-joined in registration order (valueMissing then typeMismatch), each resolving
    // to a mounted span. Proves the multi-id describedby join/ordering. No interaction.
    multiMessage: async (pg) => {
      await root(pg).locator("form").first().waitFor();
      await pg.waitForFunction(() => {
        const i = document.querySelector('input[name="email"]');
        const db = i?.getAttribute("aria-describedby");
        if (!db) return false;
        const ids = db.split(" ").filter(Boolean);
        if (ids.length !== 2) return false;
        const els = ids.map((id) => document.getElementById(id));
        if (!els.every(Boolean)) return false;
        // registration order: first id's span is the valueMissing text, second the typeMismatch.
        return (els[0].textContent || "").includes("missing")
          && (els[1].textContent || "").includes("valid email");
      });
    },
  },
  // ── Wave-B stateless depth oracles (bare primitives) ─────────────────────────────
  separatorprim: {
    // STATELESS: four at-rest combos selected by ?s=. Wait (keyed off UPSTREAM selectors)
    // for the div carrying data-orientation — the only structural marker present in all four.
    hsem: async (pg) => { await pg.locator('div[data-orientation]').first().waitFor({ state: "attached" }); },
    vsem: async (pg) => { await pg.locator('div[data-orientation]').first().waitFor({ state: "attached" }); },
    hdec: async (pg) => { await pg.locator('div[data-orientation]').first().waitFor({ state: "attached" }); },
    vdec: async (pg) => { await pg.locator('div[data-orientation]').first().waitFor({ state: "attached" }); },
  },
  aspectratioprim: {
    // STATELESS: wait for the wrapper marker attribute (present in every variant).
    default: async (pg) => { await pg.locator('[data-radix-aspect-ratio-wrapper]').first().waitFor({ state: "attached" }); },
    wide: async (pg) => { await pg.locator('[data-radix-aspect-ratio-wrapper]').first().waitFor({ state: "attached" }); },
    tall: async (pg) => { await pg.locator('[data-radix-aspect-ratio-wrapper]').first().waitFor({ state: "attached" }); },
    styled: async (pg) => { await pg.locator('[data-radix-aspect-ratio-wrapper]').first().waitFor({ state: "attached" }); },
    // Wave-C edge ratio: 21/9 → padding-bottom:42.857142857142854% (pins the non-terminating
    // decimal serialization — exercises the 100/ratio number formatting at a non-round ratio).
    verywide: async (pg) => { await pg.locator('[data-radix-aspect-ratio-wrapper]').first().waitFor({ state: "attached" }); },
  },
  visuallyhiddenprim: {
    // STATELESS: wait for the sr-only span (clip-based hiding ⇒ overflow:hidden in inline style).
    plain: async (pg) => { await pg.locator('span[style*="overflow"]').first().waitFor({ state: "attached" }); },
    props: async (pg) => { await pg.locator('span[style*="overflow"]').first().waitFor({ state: "attached" }); },
    stylemerge: async (pg) => { await pg.locator('span[style*="overflow"]').first().waitFor({ state: "attached" }); },
  },
  labelprim: {
    // STATELESS: wait for the <label> carrying the for-association attribute.
    forattrs: async (pg) => { await pg.locator('label[for]').first().waitFor({ state: "attached" }); },
  },
  // ── Wave-C: Themes.Separator WRAPPER (rt-Separator) depth oracle ─────────────────
  // STATELESS: wait for the rt-Separator span (present in every state). The contract
  // (role omitted when decorative-default, data-accent-color, size class, orientation
  // class) is judged by the DOM snapshot, not the wait.
  separatorthemes: {
    default: async (pg) => { await pg.locator("span.rt-Separator").first().waitFor({ state: "attached" }); },
    semantic: async (pg) => { await pg.locator('span.rt-Separator[role="separator"]').first().waitFor({ state: "attached" }); },
    size4: async (pg) => { await pg.locator("span.rt-Separator.rt-r-size-4").first().waitFor({ state: "attached" }); },
    accent: async (pg) => { await pg.locator('span.rt-Separator[data-accent-color="cyan"]').first().waitFor({ state: "attached" }); },
    vertical: async (pg) => { await pg.locator("span.rt-Separator.rt-r-orientation-vertical").first().waitFor({ state: "attached" }); },
  },
};
