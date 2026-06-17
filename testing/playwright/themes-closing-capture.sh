#!/usr/bin/env bash
# themes-closing-capture.sh — capture the CLOSING-STATE DOM oracle (STR-335).
#
# Radix Presence keeps a closing overlay mounted with data-state="closed" until its exit
# animation ends. This captures that transient closing DOM from the real @radix-ui/themes
# golden (with the exit animation pinned to 100s so it lingers deterministically) and writes
# the normalized result to testing/golden/themes/golden-dom/<id>.closing.txt — the external
# oracle the Halogen port's closing lifecycle is diffed against.
#
# SELF-STABILITY PROOF (the non-circular check, same as themes-open-capture.sh): each closing
# state is snapshotted TWICE; if the two normalized snapshots differ, the capture FAILS rather
# than committing a non-deterministic baseline. Same upstream twice ⇒ byte-identical.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/../.." && pwd)"
GD="$HY/testing/golden/themes"; OUT="$GD/golden-dom"; mkdir -p "$OUT"

# Overlays with a CSS [data-state="closed"] exit animation (rt-BaseDialogOverlay/Content,
# rt-PopperContent) — these are the ones radix keeps mounted via Presence on close.
STATES=("${@:-dialog}")

echo "ℵ building golden dist (bun)"
( cd "$GD" && rm -rf dist && mkdir dist && nix shell nixpkgs#bun -c bun build ./src/app.tsx --outdir dist --minify >/dev/null && cp index.html dist/ )

export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE"

fail=0
for id in "${STATES[@]}"; do
  a="$(mktemp)"; b="$(mktemp)"
  nix develop "$HY" -c node scripts/themes-closing-dom.mjs "$GD/dist" "$id" > "$a" 2>/tmp/closing-dom-err.txt || { echo "✗ $id:closing — driver error:"; cat /tmp/closing-dom-err.txt; fail=1; continue; }
  nix develop "$HY" -c node scripts/themes-closing-dom.mjs "$GD/dist" "$id" > "$b" 2>/dev/null || true
  if ! diff -q "$a" "$b" >/dev/null; then
    echo "✗ $id:closing — NON-DETERMINISTIC (normalizer/animation leaks noise):"
    diff "$a" "$b" | head -20
    fail=1; continue
  fi
  cp "$a" "$OUT/$id.closing.txt"
  echo "oracle: $id:closing  ($(wc -l < "$a") lines, stable)"
done

[ "$fail" -eq 0 ] || { echo "ℵ FAILED — some closing states were non-deterministic or errored"; exit 1; }
echo "ℵ closing-state oracle(s) → $OUT (all stable)"
