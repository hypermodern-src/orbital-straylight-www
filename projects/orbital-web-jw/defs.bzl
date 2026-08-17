load("@prelude//purescript:toolchain.bzl", "PureScriptToolchainInfo")

_GENERATE_SITE = """set -eu
path="$1"; node="$2"; compiled="$3"; site="$4"; main="$5"; page_count="$6"; shift 6
[ -n "$path" ] && export PATH="$path:${PATH:-}"
abs() { case "$1" in /*) printf '%s' "$1";; *) printf '%s/%s' "$PWD" "$1";; esac; }
compiled="$(abs "$compiled")"
site="$(abs "$site")"
mkdir -p "$site"
"$node" -e "import('$compiled/$main/index.js').then((m) => m.main())" "$site"
while [ "$page_count" -gt 0 ]; do
  test -s "$site/$1"
  shift
  page_count=$((page_count - 1))
done
while [ "$#" -gt 0 ]; do
  destination="$site/$1"
  source="$2"
  shift 2
  mkdir -p "$(dirname "$destination")"
  cp -L "$source" "$destination"
done
"""

def _orbital_static_site_impl(ctx):
    toolchain = ctx.attrs._purescript_toolchain[PureScriptToolchainInfo]
    compiled = ctx.attrs.generator[DefaultInfo].default_outputs[0]
    site = ctx.actions.declare_output(ctx.attrs.name + "-site", dir = True)
    command = cmd_args(
        "sh",
        "-c",
        _GENERATE_SITE,
        "orbital_static_site",
        toolchain.coreutils,
        toolchain.node,
        compiled,
        site.as_output(),
        ctx.attrs.main,
        str(len(ctx.attrs.required_pages)),
    )
    command.add(ctx.attrs.required_pages)
    for asset in ctx.attrs.assets:
        command.add(asset.short_path, asset)
    for bundle in ctx.attrs.client_bundles:
        command.add(bundle.basename, bundle)
    ctx.actions.run(command, category = "orbital_static_site", identifier = ctx.attrs.name)
    return [DefaultInfo(default_output = site)]

_orbital_static_site = rule(
    impl = _orbital_static_site_impl,
    attrs = {
        "generator": attrs.dep(),
        "main": attrs.string(default = "Orbital.SSG"),
        "required_pages": attrs.list(attrs.string(), default = []),
        "assets": attrs.list(attrs.source(), default = []),
        "client_bundles": attrs.list(attrs.source(), default = []),
        "_purescript_toolchain": attrs.toolchain_dep(
            default = "toolchains//:purescript",
            providers = [PureScriptToolchainInfo],
        ),
    },
)

def orbital_static_site(name, generator, main = "Orbital.SSG", required_pages = [], assets = [], client_bundles = [], visibility = ["PUBLIC"]):
    _orbital_static_site(
        name = name,
        generator = generator,
        main = main,
        required_pages = required_pages,
        assets = assets,
        client_bundles = client_bundles,
        visibility = visibility,
    )
