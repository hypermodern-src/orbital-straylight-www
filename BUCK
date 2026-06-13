# hydrogen — the PureScript/Halogen framework, as a first-class buck2 library cell.
#
# Apps consume this as `deps = ["hydrogen//:lib"]` (after wiring hydrogen as a
# cell: a pinned flake input symlinked to nix/build/hydrogen + a [cells] entry).
# purescript_library does no compilation — it exposes src/**/*.purs (+ adjacent
# FFI .js) as a dep directory; the consuming app compiles hydrogen's source
# alongside its own, and hydrogen's registry deps ride in via the app's resolved
# package closure (the app's spago solve already included hydrogen). See
# straylight-prelude STR-234.
purescript_library(
    name = "lib",
    srcs = glob(["src/**/*.purs", "src/**/*.js"]),
    visibility = ["PUBLIC"],
)
