#!/usr/bin/env bash
# Capture the GOLDEN set: upstream Radix Themes' render of each ?c=<id> page.
# Run when the golden app's component set changes; PNGs are committed.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/../.." && pwd)"
GD="$HY/testing/golden/themes"; OUT="$GD/golden"; mkdir -p "$OUT"
echo "ℵ building golden dist (bun)"
( cd "$GD" && rm -rf dist && mkdir dist && nix shell nixpkgs#bun -c bun build ./src/app.tsx --outdir dist --minify >/dev/null && cp index.html dist/ )
source "$HERE/pinned-browsers.sh"  # pinned, version-matched browser set (see that file)
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
cd "$HERE"
for id in button checkbox switch textfield textarea badge callout card avatar spinner progress separator code kbd quote blockquote emstrong link radiogroup slider tabs table datalist signin \
          container grid section inset aspectratio iconbutton skeleton visuallyhidden accessibleicon tabnav segmentedcontrol checkboxgroup checkboxcards radiocards; do
  nix develop "$HY" -c node scripts/themes-shoot.mjs "$GD/dist" "/?c=$id" "$OUT/$id.png" >/dev/null
  echo "golden: $id"
done
echo "ℵ $(ls "$OUT" | wc -l) goldens → $OUT"
