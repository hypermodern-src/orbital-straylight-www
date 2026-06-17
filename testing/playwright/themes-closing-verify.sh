#!/usr/bin/env bash
# themes-closing-verify.sh [<id> …] — the CLOSING-state DOM gate (STR-335).
#
# Builds the Halogen port, drives each overlay through the SAME open→Escape→snapshot script
# as the golden (scripts/themes-closing-dom.mjs), and diffs the port's normalized CLOSING-state
# DOM against the committed oracle testing/golden/themes/golden-dom/<id>.closing.txt.
#
# Exit 0 = the port keeps the closing overlay mounted with data-state="closed" (Presence
# exit-animation lifecycle) byte-identically to real radix-themes. The non-circular bar:
# validated on the golden FIRST (themes-closing-capture.sh), then run against the port here.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/../.." && pwd)"
OUT="$HY/testing/golden/themes/golden-dom"

if [ "$#" -eq 0 ]; then
  set -- $(cd "$OUT" && for f in *.closing.txt; do [ -e "$f" ] || continue; echo "${f%.closing.txt}"; done)
fi

echo "ℵ building the Halogen port (//examples/themes-interactive:app)"
DIST="$HERE/.themes-closing-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/themes-interactive:app --out "$DIST" >/tmp/themes-closing-build.log 2>&1 ) \
  || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/themes-closing-build.log | grep -v Compiling | head; exit 1; }

export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE"

fail=0
for id in "$@"; do
  gold="$OUT/$id.closing.txt"
  [ -f "$gold" ] || { echo "✗ $id:closing — no oracle ($gold); run themes-closing-capture.sh"; fail=1; continue; }
  ours="$(mktemp)"
  if ! nix develop "$HY" -c node scripts/themes-closing-dom.mjs "$DIST" "$id" > "$ours" 2>/tmp/closing-dom-err.txt; then
    echo "✗ $id:closing — port driver error:"; cat /tmp/closing-dom-err.txt; fail=1; continue
  fi
  if diff -q "$gold" "$ours" >/dev/null; then
    echo "✓ $id:closing — CLOSING DOM-IDENTICAL to upstream (Presence exit lifecycle matches)"
  else
    echo "✗ $id:closing differs (< upstream oracle  > port):"
    diff "$gold" "$ours" || true
    fail=1
  fi
done

[ "$fail" -eq 0 ] || { echo "ℵ closing-state gate FAILED"; exit 1; }
echo "ℵ closing-state gate PASS"
