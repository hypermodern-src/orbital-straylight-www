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
  "alertdialog:open"
  "popover:open"
  "tooltip:open"
  "hovercard:open"
  "dropdownmenu:open"
  "dropdownmenu:item2"
  "dropdownmenu:disabled"
  "contextmenu:open"
  "contextmenu:item2"
  "contextmenu:disabled"
  "select:open"
  # Interactive (stateful, non-overlay) components — STR (13 new oracles).
  "accordion:open"
  "collapsible:open"
  "toast:open"
  "menubar:open"
  "menubar:item1"
  "menubar:disabled"
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
  "form:multiMessage"
  # STR-330 wave-b structural depth gaps (Progress / Collapsible / Avatar).
  "collapsible:disabled"
  "progress:indeterminate"
  "progress:complete"
  "progress:custommax"
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
  "visuallyhiddenprim:plain"
  "visuallyhiddenprim:props"
  "visuallyhiddenprim:stylemerge"
  "labelprim:forattrs"
  # ── Wave-C ScrollArea family depth oracles (STR-330) ─────────────────────────
  "scrollareax:horizontal"
  "scrollareax:both"
  # ── Wave-C Collapsible closed-rest DOM oracle (STR-330) ──────────────────────
  "collapsible:rest"
  # ── Wave-C Progress out-of-range validation oracle (STR-330) ─────────────────
  "progress:invalid"
  # ── Wave-C Avatar loaded steady-state DOM oracle (STR-330) ───────────────────
  "avatar:loaded"
)

echo "ℵ building golden dist (bun)"
( cd "$GD" && rm -rf dist && mkdir dist && nix shell nixpkgs#bun -c bun build ./src/app.tsx --outdir dist --minify >/dev/null && cp index.html dist/ )

export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
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
