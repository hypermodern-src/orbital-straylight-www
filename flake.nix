{
  description = "hydrogen — PureScript/Halogen framework + component library (Hydrogen.Radix.*), on the straylight-prelude buck2 build. `nix develop -c buck2 build //check:hydrogen_check` typechecks the whole tree (cached).";

  inputs = {
    # LOCAL prelude checkout so the purescript_library `_check` co-design change
    # (cached library typecheck) flows through. Repoint to the git URL once pushed.
    straylight-prelude.url = "path:/home/b7r6/src/straylight/straylight-prelude";
    flake-parts.follows = "straylight-prelude/flake-parts";
    nixpkgs.follows = "straylight-prelude/nixpkgs";
    systems.follows = "straylight-prelude/systems";
  };

  outputs =
    inputs@{ flake-parts, straylight-prelude, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        straylight-prelude.flakeModules.std
        straylight-prelude.flakeModules.straylight-prelude
      ];
      perSystem =
        { ... }:
        {
          # hydrogen as its own buck2 project: the source IS the framework +
          # component library. The check target compiles the whole tree against the
          # registry closure (committed in check/BUCK) — a cached self-typecheck.
          #
          #   nix build           → typecheck the tree (a library's "build" is its
          #                         typecheck; packages.default, single-project flake).
          #   nix flake check     → the `typecheck` gate below (cxx is off, so the
          #                         clang-tidy gate doesn't apply — this is what makes
          #                         `nix flake check` mean something for PureScript).
          #
          # When the Playwright gallery becomes a `buck2 test` target (STR-319,
          # purs_playwright_test), add `gates.gallery = { target = "..."; mode =
          # "test"; }` and it joins `nix flake check` on the same rail.
          straylight-prelude.projects.hydrogen-ps = {
            src = ./.;
            targets = [ "//check:hydrogen_check" ];
            gates.typecheck.target = "//check:hydrogen_check";
            toolchain = {
              cxx.enable = false;
              purescript.enable = true;
            };
          };
        };
    };
}
