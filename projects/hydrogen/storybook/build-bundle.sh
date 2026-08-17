#!/usr/bin/env bash
# Build the Halogen Hydrogen.Themes FFI bundle with Spago into dist/, alongside the
# Radix stylesheet — both served by Storybook (staticDirs) + loaded in preview-head.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; HY="$(cd "$HERE/.." && pwd)"
mkdir -p "$HERE/dist"
( cd "$HERE" && PATH="$HY/node_modules/.bin:$PATH" spago bundle --module Storybook.Mount --platform browser --bundle-type app --outfile "$HERE/dist/hydrogen-stories.js" --strict )
cp "$HERE/themes.css" "$HERE/dist/themes.css"
echo "ℵ bundle + styles → $HERE/dist"
