# hydrogen//:defs.bzl — the plugin/integration frame, as buck2 macros.
#
# straylight-prelude takes NO position on hydrogen: it ships only language/build
# primitives (purescript_app, purescript_library, the npm placement-tree closure,
# purs_site, purs_browser_bundle, artifacts, cells). The FRAME lives here, in
# hydrogen, composed FROM those primitives. Any hydrogen-like framework ships its
# own defs.bzl against the same prelude — that is the agnosticism, concretely.
#
# Cell bases (buck2 resolves `//` against the cell of the BUCK file being
# evaluated, not this .bzl's cell):
#   * hydrogen_app runs in a CONSUMER's cell -> it references `hydrogen//…`
#     (consumers wire the hydrogen cell under that alias in .buckconfig).
#   * hydrogen_integration runs INSIDE hydrogen -> it references `//…`.

load("@prelude//:purescript.bzl", "purescript_app", "purescript_library")

# Integration short-name -> its library target in the hydrogen cell. Adding an
# integration to the frame is one line here.
_INTEGRATIONS = {
    "supabase": "hydrogen//integrations/supabase:lib",
    "clerk": "hydrogen//integrations/clerk:lib",
}

def hydrogen_app(
        name,
        srcs,
        main = "Main",
        integrations = [],
        deps = [],
        **kwargs):
    """A hydrogen application. A purescript_app that always depends on the
    hydrogen core library (Hydrogen.*, incl. the Frame hook typeclasses) and on
    each named integration. An integration's npm SDK closure rides up
    transitively via PursLibInfo — the app lists `integrations = ["supabase"]`
    and never declares the SDK's npm packages itself.

    Forwards everything else (packages, browser_bundle, bundle_name, ssg_main,
    index_html, …) straight to purescript_app."""
    integration_deps = [_INTEGRATIONS[i] for i in integrations]
    purescript_app(
        name = name,
        srcs = srcs,
        main = main,
        deps = ["hydrogen//:lib"] + integration_deps + deps,
        **kwargs
    )

def hydrogen_integration(
        name,
        srcs,
        npm_packages = [],
        npm_externals = [],
        deps = [],
        visibility = ["PUBLIC"]):
    """The canonical way to declare an integration (used WITHIN hydrogen). A
    purescript_library that depends on hydrogen core (for the Frame hook
    typeclasses it implements) and carries the integration's npm closure
    (inherited by consuming apps via PursLibInfo). Use the placement-tree
    manifest (npm_packages + npm_externals) from npm-resolve-lock.py for SDKs
    with real dependency trees."""
    purescript_library(
        name = name,
        srcs = srcs,
        deps = ["//:lib"] + deps,
        npm_packages = npm_packages,
        npm_externals = npm_externals,
        visibility = visibility,
    )
