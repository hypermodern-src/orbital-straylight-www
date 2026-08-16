{
  description = "straylight-web PureScript — flagship hydrogen app on the canonical buck2 build (paved-path demo)";

  inputs = {
    straylight-prelude.url = "git+ssh://git@github.com/sensenet-ai/straylight-prelude";
    flake-parts.follows = "straylight-prelude/flake-parts";
    nixpkgs.follows = "straylight-prelude/nixpkgs";
    systems.follows = "straylight-prelude/systems";

    hydrogen = {
      url = "git+ssh://git@git.s4.gl/straylight/hydrogen?ref=main&rev=8afd5e6358609e8532bdef56e2f21545064df8cc";
      flake = false;
    };
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
          straylight-prelude.projects.straylight-web-ps = {
            src = ./.;
            cells.hydrogen = inputs.hydrogen;
            targets = [ "//:web" ];
            gates.bundle.target = "//:web";
            toolchain = {
              cxx.enable = false;
              purescript.enable = true;
            };
            # Materialize the browser bundle as a store path the root Next/bun2nix
            # flake copies into public/ before `next build` (STR-236/237). Build:
            #   nix build .#straylight-prelude-straylight-web-ps-artifact-straylight-js
            artifacts.straylight-js = {
              target = "//:web";
              out = "straylight.js";
            };
          };
        };
    };
}
