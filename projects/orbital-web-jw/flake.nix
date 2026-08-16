{
  description = "Orbital product site — typed Hydrogen SSG on the canonical straylight-prelude Buck2 build";

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
        { pkgs, ... }:
        let
          vercelDeployTarget = import ./nix/vercel-deploy-target.nix { inherit pkgs; };
        in
        {
          straylight-prelude.projects.orbital-web-jw = {
            src = ./.;
            cells.hydrogen = inputs.hydrogen;
            targets = [ "//:site" ];
            gates.site.target = "//:site";
            toolchain = {
              cxx.enable = false;
              purescript.enable = true;
            };
            deploy.site = {
              target = "//:site";
              provider = vercelDeployTarget;
            };
          };
        };
    };
}
