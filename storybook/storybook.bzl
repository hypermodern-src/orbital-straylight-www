# Hermetic Storybook build over a bun2nix-provided node_modules.
#
# The prelude's `npm_build` sources its node_modules from the http_archive
# placement list (npm-resolve-lock.py / the Clerk model). Storybook's toolchain
# (vite + esbuild's platform binaries + postinstalls) is exactly the case where a
# real, offline-materialized node_modules is safer — which is what bun2nix already
# gives us (the flake's toolchain.purescript.bun2nix.storybook, store path in
# .buckconfig.local as bun2nix_storybook). This rule is `npm_build` with the
# node_modules sourced from that store path instead.
#
# TODO(prelude): upstream as `npm_build(npm_packages = "bun2nix#<name>")` so the
# documented bun2nix fragment works for npm_build too, not just esbuild NODE_PATH.

_BUILD = """
set -eu
node="$1"; outp="$2"; srctree="$3"; nm="$4"; outdir="$5"; cmd="$6"
abs() { case "$1" in /*) printf '%s' "$1";; *) printf '%s/%s' "$PWD" "$1";; esac; }
nodeb="$(dirname "$(abs "$node")")"
src="$(abs "$srctree")"; mods="$(abs "$nm")"; dest="$(abs "$outp")"
# stage sources + a writable copy of the bun2nix node_modules, run the build, capture out_dir.
build=$(mktemp -d)
cp -RL "$src"/. "$build"/
# bun2nix's default is the isolated layout: top-level node_modules only symlinks
# the direct deps, while the flat, node-resolvable tree lives in .bun/node_modules.
# Use that as the build's node_modules so plain `node` resolves transitive deps.
realmods="$mods"; [ -d "$mods/.bun/node_modules" ] && realmods="$mods/.bun/node_modules"
cp -RL "$realmods" "$build/node_modules"
chmod -R u+w "$build/node_modules"
cd "$build"
export HOME="$build" PATH="$nodeb:$PATH" CI=1 NODE_ENV=production STORYBOOK_DISABLE_TELEMETRY=1
sh -c "$cmd"
mkdir -p "$dest"
cp -RL "$build/$outdir"/. "$dest"/
"""

def _impl(ctx: AnalysisContext) -> list[Provider]:
    srctree = ctx.actions.symlinked_dir(
        ctx.attrs.name + "-src",
        {s.short_path: s for s in ctx.attrs.srcs},
    )
    out = ctx.actions.declare_output(ctx.attrs.name + "-out", dir = True)
    cmd = cmd_args([
        "sh", "-c", _BUILD, "storybook_static",
        ctx.attrs.node,
        out.as_output(),
        srctree,
        ctx.attrs.node_modules,
        ctx.attrs.out_dir,
        ctx.attrs.cmd,
    ])
    ctx.actions.run(cmd, category = "storybook", identifier = ctx.attrs.name, local_only = True)
    return [DefaultInfo(default_output = out)]

_storybook_static = rule(impl = _impl, attrs = {
    "srcs": attrs.list(attrs.source(allow_directory = True), default = []),
    "node": attrs.string(),
    "node_modules": attrs.string(),
    "out_dir": attrs.string(default = "out"),
    "cmd": attrs.string(default = ""),
})

def storybook_static(name, srcs, out_dir, cmd, bun2nix, visibility = ["PUBLIC"]):
    _storybook_static(
        name = name,
        srcs = srcs,
        node = read_root_config("purescript", "node", "node"),
        node_modules = read_root_config("purescript", "bun2nix_" + bun2nix, ""),
        out_dir = out_dir,
        cmd = cmd,
        visibility = visibility,
    )

# ── dev server (`buck2 run //storybook:dev`) ─────────────────────────────────
# Launches the Storybook/Vite dev server (HMR over the live stories + preview) with
# the hermetic node_modules materialized writable from the bun2nix store. The
# buck2-built FFI bundle is staged into dist/ so the components render. The
# canonical/CI build stays //storybook:static; this is the fast inner loop.

_DEV = """#!/usr/bin/env bash
set -eu
bundle="$(realpath "$1")"
root="$(git rev-parse --show-toplevel 2>/dev/null)" || {{ echo "run from within the hydrogen repo"; exit 1; }}
cd "$root/storybook"
# writable node_modules from the bun2nix store (.bun/node_modules is the flat,
# node-resolvable tree); materialized once, then reused.
if [ ! -e node_modules/.dev-stamp ]; then
  echo "ℵ materializing hermetic node_modules (one-time, from bun2nix)…"
  rm -rf node_modules; cp -RL "{nm}/.bun/node_modules" node_modules
  chmod -R u+w node_modules; : > node_modules/.dev-stamp
fi
# the FFI bundle + stylesheet that staticDirs (../dist) serves
mkdir -p dist; cp -f "$bundle" dist/hydrogen-stories.js; cp -f themes.css dist/themes.css
echo "ℵ storybook dev → http://localhost:{port}"
exec "{node}" node_modules/storybook/bin/index.cjs dev -p {port} --no-open
"""

def _dev_impl(ctx: AnalysisContext) -> list[Provider]:
    script = ctx.actions.write(
        "storybook-dev.sh",
        _DEV.format(nm = ctx.attrs.node_modules, node = ctx.attrs.node, port = ctx.attrs.port),
        is_executable = True,
    )
    # the bundle rides along ($1) so buck2 builds it before launching the server.
    run = cmd_args([script, ctx.attrs.bundle])
    return [DefaultInfo(default_output = script), RunInfo(args = run)]

_storybook_dev = rule(impl = _dev_impl, attrs = {
    "bundle": attrs.source(),
    "node": attrs.string(),
    "node_modules": attrs.string(),
    "port": attrs.string(default = "6006"),
})

def storybook_dev(name, bundle, bun2nix, port = "6006", visibility = ["PUBLIC"]):
    _storybook_dev(
        name = name,
        bundle = bundle,
        node = read_root_config("purescript", "node", "node"),
        node_modules = read_root_config("purescript", "bun2nix_" + bun2nix, ""),
        port = port,
        visibility = visibility,
    )
