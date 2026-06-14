# hydrogen//:lib — the framework as a first-class buck2 library, an AGGREGATE over
# the per-directory layer libraries (no globs; every directory carries its own BUCK
# and `//path:target` mirrors the tree). srcs is empty: this target carries no
# files of its own, only the transitive source closure of its deps (the prelude's
# purescript_library propagates sources transitively via PursLibInfo).
#
# Apps consume this as `deps = ["hydrogen//:lib"]` (after wiring hydrogen as a cell:
# a pinned flake input symlinked to nix/build/hydrogen + a [cells] entry); the
# consuming app compiles hydrogen's source alongside its own, and hydrogen's
# registry deps ride in via the app's resolved package closure. See
# straylight-prelude STR-234.
#
# These three deps reach every layer: the umbrella pulls data/runtime/ui, frame
# pulls runtime, and radix pulls behavior/float/foundation.
purescript_library(
    name = "lib",
    srcs = [],
    deps = [
        "//src:hydrogen",
        "//src/Hydrogen:frame",
        "//src/Hydrogen/Radix:radix",
    ],
    visibility = ["PUBLIC"],
)
