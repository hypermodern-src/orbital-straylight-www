#!/usr/bin/env bash
# themes-open-capture.sh — capture the OPEN-STATE DOM oracle (STR-331).
#
# Builds the golden dist (real @radix-ui/themes), drives each interactive component
# into its states, and writes the normalized DOM to testing/golden/themes/golden-dom/
# <id>.<state>.txt — the committed external oracle the Halogen port is diffed against.
#
# SELF-STABILITY PROOF (the honest, non-circular check): each state is snapshotted
# TWICE; if the two normalized snapshots differ, the normalizer is leaking run-to-run
# noise (an un-canonicalized id or pixel) and the capture FAILS rather than committing
# a non-deterministic baseline. Same upstream twice ⇒ byte-identical, or it's not an
# oracle.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/../.." && pwd)"
GD="$HY/testing/golden/themes"; OUT="$GD/golden-dom"; mkdir -p "$OUT"

# id:state matrix — extend as states/components are added.
STATES=(
  "dialog:open"
  "dialog:closed-attr"
  "alertdialog:open"
  "alertdialog:aria-controls"
  "popover:open"
  "popover:closed-attr"
  "tooltip:open"
  "tooltip:closed-rest"
  "hovercard:open"
  "dropdownmenu:open"
  "dropdownmenu:closed-rest"
  "dropdownmenu:item2"
  "dropdownmenu:disabled"
  "dropdownmenu:submenu"
  "contextmenu:open"
  "contextmenu:closed-rest"
  "contextmenu:item2"
  "contextmenu:disabled"
  "contextmenu:submenu"
  "select:open"
  "select:closed-rest"
  # Interactive (stateful, non-overlay) components — STR (13 new oracles).
  "accordion:open"
  "collapsible:open"
  "toast:open"
  "menubar:open"
  "menubar:closed-rest"
  "menubar:item1"
  "menubar:disabled"
  "menubar:submenu"
  "navigationmenu:closed"
  "navigationmenu:open"
  "tabs:tab2"
  "radiogroup:checked"
  "checkbox:checked"
  "switch:on"
  "toggle:pressed"
  "togglegroup:pressed"
  "segmentedcontrol:selected"
  "checkboxgroup:checked"
  "radiocards:selected"
  "checkboxcards:selected"
  "tabnav:active"
  "slider:stepped"
  "scrollarea:shown"
  "progress:shown"
  "accessibleicon:shown"
  # Bare @radix-ui/react-* primitives Radix Themes ships no component for (STR-330).
  "toolbar:default"
  "toolbar:vertical"
  "toolbar:roved"
  "passwordtoggle:hidden"
  "passwordtoggle:visible"
  "otp:filled"
  "otp:empty"
  "otp:typed"
  "form:rest-valid"
  "form:serverInvalid"
  "form:forceMatch"
  "form:valueMissing"
  "form:typeMismatch"
  # ── Wave-B nav-group depth oracles (STR-330) ─────────────────────────────────
  "tooltip:focusopen"
  "hovercard:richcontent"
  "navigationmenu:vertical"
  "navigationmenu:clicktoggle"
  "navigationmenu:rtl"
  # wave-b roving depth gaps (STR-330): new DOM oracles.
  "togglegroup:multiple"
  "accordion:multiple"
  "accordion:single"
  "toolbar:disabled"
  # Wave-B controls — core+common depth-audit close-out (STR-330).
  "toggle:rest"
  "toggle:disabled"
  "switch:rest"
  "switch:disabled"
  "switch:required"
  "checkbox:indeterminate"
  "checkbox:disabled"
  "radiogroup:keys"
  "radiogroup:mixed"
  "radiogroup:disabledgroup"
  "radiogroup:horizontal"
  # Wave-B inputs depth-audit additions (STR-330).
  "slider:rest"
  "slider:disabled"
  "otp:alpha"
  "otp:alphanumeric"
  "otp:named"
  "otp:placeholder"
  "otp:novalidation"
  "form:multiMessage"
  # STR-330 wave-b structural depth gaps (Progress / Collapsible / Avatar).
  "collapsible:disabled"
  "progress:indeterminate"
  "progress:complete"
  "progress:custommax"
  # Wave-D: themes color+radius passthrough (data-accent-color / data-radius on root).
  "progress:accent"
  "avatar:fallback"
  # Wave-B stateless depth oracles (bare primitives).
  "separatorprim:hsem"
  "separatorprim:vsem"
  "separatorprim:hdec"
  "separatorprim:vdec"
  "aspectratioprim:default"
  "aspectratioprim:wide"
  "aspectratioprim:tall"
  "aspectratioprim:styled"
  "aspectratioprim:verywide"
  "visuallyhiddenprim:plain"
  "visuallyhiddenprim:props"
  "visuallyhiddenprim:stylemerge"
  "labelprim:forattrs"
  # Wave-C modal depth gaps (STR-330): PopoverClose variant (a Popover.Close submit button).
  "popover:close"
  # ── Wave-C menus depth (STR-330): DropdownMenu CheckboxItem / RadioItem ──────────
  "dropdownmenuchecks:checkbox"
  "dropdownmenuchecks:radio"
  "contextmenuchecks:checkbox"
  "contextmenuchecks:radio"
  "menubarchecks:checkbox"
  "menubarchecks:radio"
  "selectplaceholder:placeholder"
  # ── Wave-C controls — form participation (hidden bubble input) depth gaps (STR-330) ─
  "checkbox:form"
  "switch:form"
  "radiogroup:form"
  # Wave-C Toggle — the disabled-AND-pressed edge state-variant (STR-330).
  "toggle:disabledpressed"
  # ── Wave-C inputs depth-audit additions (STR-330) ────────────────────────────
  "slider:vertical"
  "otp:password"
  "otp:disabled"
  "otp:readonly"
  "passwordtoggle:autolabel"
  "passwordtoggle:disabled"
  "form:validValid"
  "form:defaultMessage"
  # ── Wave-C ScrollArea family depth oracles (STR-330) ─────────────────────────
  "scrollareax:horizontal"
  "scrollareax:both"
  # ── Wave-D ScrollArea themes `radius` prop oracle (STR-330) ──────────────────
  "scrollareax:radius"
  # ── Wave-C Collapsible closed-rest DOM oracle (STR-330) ──────────────────────
  "collapsible:rest"
  # ── Wave-C Progress out-of-range validation oracle (STR-330) ─────────────────
  "progress:invalid"
  # ── Wave-C Avatar loaded steady-state DOM oracle (STR-330) ───────────────────
  "avatar:loaded"
  # ── Wave-D Avatar img-attr passthrough (referrerPolicy/crossOrigin on <img>) ──
  "avatar:loadedattrs"
  "labelprim:forfocus"
  # Wave-C: Themes.Separator WRAPPER depth oracle.
  "separatorthemes:default"
  "separatorthemes:semantic"
  "separatorthemes:size4"
  "separatorthemes:accent"
  "separatorthemes:vertical"
  # ── Wave-D menus depth (STR-330): Select form integration + DropdownMenu groups ──
  "selectform:required"
  "dropdownmenugroup:open"
  "toast-up:open"
  # Wave-D Tabs zero-selected (no defaultValue → '' active; no tab selected, all panels hidden).
  "tabsnone:none"
  # ── Wave-D: multi-thumb / RANGE slider (value is number[]) ───────────────────
  "sliderrange:default"
  "sliderrange:triple"
  "sliderrange:minsteps"
  # ── STR-330 (parity): multi-thumb Slider FORM participation (SliderBubbleInput) ──
  "sliderrangeform:default"
  # ── Wave-D: OTP paste / autocomplete-dump (value.length>1 ⇒ PASTE reducer) ──
  "otp:paste"
  # ── Wave-D: PasswordToggleField form-reset → visibility back to hidden ──────
  "passwordtoggle:formreset"
  # ── Wave-D: Form reset → clears validity (Messages unmount, data-invalid drops) ──
  "form:reset"
  # Wave-D: Label onMouseDown guard — DOM snapshot (the guard itself is APG-adjudicated).
  "labelguard:plain"
  "labelguard:control"
)

echo "ℵ building golden dist (bun)"
( cd "$GD" && rm -rf dist && mkdir dist && nix shell nixpkgs#bun -c bun build ./src/app.tsx --outdir dist --minify >/dev/null && cp index.html dist/ )

source "$HERE/pinned-browsers.sh"  # pinned, version-matched browser set (see that file)
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE"

fail=0
for s in "${STATES[@]}"; do
  id="${s%%:*}"; state="${s##*:}"
  a="$(mktemp)"; b="$(mktemp)"
  nix develop "$HY" -c node scripts/themes-open-dom.mjs "$GD/dist" "$id" "$state" > "$a" 2>/tmp/open-dom-err.txt || { echo "✗ $id:$state — driver error:"; cat /tmp/open-dom-err.txt; fail=1; continue; }
  nix develop "$HY" -c node scripts/themes-open-dom.mjs "$GD/dist" "$id" "$state" > "$b" 2>/dev/null || true
  if ! diff -q "$a" "$b" >/dev/null; then
    echo "✗ $id:$state — NON-DETERMINISTIC (normalizer leaks noise):"
    diff "$a" "$b" | head -20
    fail=1; continue
  fi
  cp "$a" "$OUT/$id.$state.txt"
  echo "oracle: $id:$state  ($(wc -l < "$a") lines, stable)"
done

[ "$fail" -eq 0 ] || { echo "ℵ FAILED — some states were non-deterministic or errored"; exit 1; }
echo "ℵ $(ls "$OUT" | wc -l) open-state oracles → $OUT (all stable)"
