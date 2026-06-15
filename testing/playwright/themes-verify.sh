#!/usr/bin/env bash
# themes-verify.sh <id> — build the Halogen port, screenshot ?c=<id>, sha-compare
# to testing/golden/themes/golden/<id>.png. Exit 0 = PIXEL-IDENTICAL. On mismatch,
# prints the DOM diff (gold vs ours) to localize the delta. The swarm's gate.
set -euo pipefail
id="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/../.." && pwd)"
GOLD="$HY/testing/golden/themes/golden/$id.png"
[ -f "$GOLD" ] || { echo "no golden for '$id' ($GOLD)"; exit 2; }
DIST="$HERE/.themes-dist"; rm -rf "$DIST"
( cd "$HY" && nix develop -c buck2 build //examples/themes-port:app --out "$DIST" >/tmp/themes-verify-build.log 2>&1 ) || { echo "BUILD FAILED:"; grep -nE 'Error|in module|not in scope' /tmp/themes-verify-build.log | grep -v Compiling | head; exit 1; }
export PLAYWRIGHT_BROWSERS_PATH="$(nix build nixpkgs#playwright-driver.browsers --no-link --print-out-paths)"
export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
OURS="/tmp/ours-$id.png"
( cd "$HERE" && nix develop "$HY" -c node scripts/themes-shoot.mjs "$DIST" "/?c=$id" "$OURS" >/dev/null )
if [ "$(sha256sum < "$OURS")" = "$(sha256sum < "$GOLD")" ]; then
  echo "✓ $id PIXEL-IDENTICAL"; exit 0
fi
echo "✗ $id differs. DOM diff (< golden  > ours):"
( cd "$HERE" && nix develop "$HY" -c node scripts/themes-dom.mjs "$HY/testing/golden/themes/dist" "/?c=$id" > /tmp/dom-gold-$id.txt 2>/dev/null   && nix develop "$HY" -c node scripts/themes-dom.mjs "$DIST" "/?c=$id" > /tmp/dom-ours-$id.txt 2>/dev/null )
diff "/tmp/dom-gold-$id.txt" "/tmp/dom-ours-$id.txt" || true
exit 1
