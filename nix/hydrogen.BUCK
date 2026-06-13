# Library BUCK overlaid onto the pinned hydrogen source (see flake.nix
# cells.hydrogen). This is a TEMPORARY bridge: the same file is committed to
# hydrogen itself (straylight-software/hydrogen, awaiting merge — the author here
# only has READ). Once it lands upstream, drop this file + the overlay and use
# `cells.hydrogen = inputs.hydrogen` directly.
#
# purescript_library exposes src/**/*.purs (+ adjacent FFI .js) as a dep
# directory; reinit compiles hydrogen's source alongside its own, and hydrogen's
# registry deps ride in via reinit's resolved package closure (STR-234).
purescript_library(
    name = "lib",
    srcs = glob(["src/**/*.purs", "src/**/*.js"]),
    visibility = ["PUBLIC"],
)
