#!/usr/bin/env bash
# Build the Halogen Hydrogen.Themes FFI bundle (buck2) into dist/, alongside the
# Radix stylesheet — both served by Storybook (staticDirs) + loaded in preview-head.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
mkdir -p "$HERE/dist"
( cd "$HY" && nix develop -c buck2 build //storybook:bundle --out "$HERE/dist/hydrogen-stories.js" )
cp "$HERE/themes.css" "$HERE/dist/themes.css"
echo "ℵ bundle + styles → $HERE/dist"
