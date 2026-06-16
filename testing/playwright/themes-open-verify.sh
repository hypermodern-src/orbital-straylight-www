#!/usr/bin/env bash
# themes-open-verify.sh [<id>[:<state>] …] — the open-state DOM gate (STR-331).
#
# Builds the Halogen port, drives each interactive component through the SAME state
# script as the golden (scripts/themes-open-dom.mjs — the single source of truth, keyed
# off upstream class/role selectors the port must reproduce), and diffs its normalized
# open-state DOM against the committed oracle testing/golden/themes/golden-dom/<id>.<state>.txt.
#
# Exit 0 = the port's interacted DOM == real radix-themes' interacted DOM. This is the
# non-circular bar every P2/P3 interactive component must meet — the open-state analogue
# of the at-rest sha256 pixel gate. With no args, verifies every committed oracle.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/../.." && pwd)"
OUT="$HY/testing/golden/themes/golden-dom"

# default: every committed oracle (<id>.<state>.txt → <id>:<state>)
if [ "$#" -eq 0 ]; then
  set -- $(cd "$OUT" && for f in *.txt; do b="${f%.txt}"; echo "${b%.*}:${b##*.}"; done)
fi

echo "ℵ building the Halogen port (//examples/themes-port:app)"
DIST="$HERE/.themes-open-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/themes-port:app --out "$DIST" >/tmp/themes-open-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/themes-open-build.log | grep -v Compiling | head; exit 1; }

export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE"

fail=0
for s in "$@"; do
  id="${s%%:*}"; state="${s##*:}"; [ "$state" = "$id" ] && state="open"
  gold="$OUT/$id.$state.txt"
  [ -f "$gold" ] || { echo "✗ $id:$state — no oracle ($gold); run themes-open-capture.sh"; fail=1; continue; }
  ours="$(mktemp)"
  if ! nix develop "$HY" -c node scripts/themes-open-dom.mjs "$DIST" "$id" "$state" > "$ours" 2>/tmp/open-dom-err.txt; then
    echo "✗ $id:$state — port driver error:"; cat /tmp/open-dom-err.txt; fail=1; continue
  fi
  if diff -q "$gold" "$ours" >/dev/null; then
    echo "✓ $id:$state — DOM-IDENTICAL to upstream"
  else
    echo "✗ $id:$state differs (< upstream oracle  > port):"
    diff "$gold" "$ours" || true
    fail=1
  fi
done

[ "$fail" -eq 0 ] || { echo "ℵ open-state gate FAILED"; exit 1; }
echo "ℵ open-state gate PASS"
