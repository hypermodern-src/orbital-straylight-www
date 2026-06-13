{
  description = "straylight-web PureScript — flagship hydrogen app on the canonical buck2 build (paved-path demo)";

  inputs = {
    straylight-prelude.url = "git+ssh://git@github.com/sensenet-ai/straylight-prelude";
    flake-parts.follows = "straylight-prelude/flake-parts";
    nixpkgs.follows = "straylight-prelude/nixpkgs";
    systems.follows = "straylight-prelude/systems";

    hydrogen = {
      url = "git+ssh://git@github.com/sensenet-ai/hydrogen?ref=main&rev=9f02b5b7db6f5dc3f5363996526ba6ac93cf8f26";
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
            toolchain = {
              cxx.enable = false;
              purescript.enable = true;
            };
          };
        };
    };
}
