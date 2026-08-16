{
  description = "REINIT // DX — the reference hydrogen app on the canonical straylight-prelude buck2 build (no spago)";

  inputs = {
    # The prelude carries the PureScript rules (purescript_library, purs_site),
    # the extra-cell mechanism, and the Vercel deploy convention. git+ssh (not the
    # github: API fetcher) because the repos are private.
    straylight-prelude.url = "git+ssh://git@github.com/sensenet-ai/straylight-prelude";
    flake-parts.follows = "straylight-prelude/flake-parts";
    nixpkgs.follows = "straylight-prelude/nixpkgs";
    systems.follows = "straylight-prelude/systems";

    # hydrogen as a first-class library cell — pinned source whose BUCK exposes
    # purescript_library (STR-234). Just the source tree, not a flake.
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
          straylight-prelude.projects.reinit-dx = {
            src = ./.;
            # hydrogen rides in as a buck2 cell (STR-234): consumed as
            # `deps = ["hydrogen//:lib"]` in ./BUCK; the [cells] entry is in
            # .buckconfig; the symlink is materialized by the project mechanism.
            # hydrogen carries its own purescript_library BUCK, so the pinned
            # input is the cell directly.
            cells.hydrogen = inputs.hydrogen;
            targets = [ "//:site" ];
            gates.site.target = "//:site";
            toolchain = {
              # Pure PureScript — no C++ toolchain / clang-tidy gate.
              cxx.enable = false;
              purescript.enable = true;
            };
            # The deployable static site (SSG index.html + reinit.js), pushed to
            # Vercel as a Build-Output-API prebuilt tree:
            #   nix run .#deploy-reinit-dx-site-vercel
            deploy.site = {
              target = "//:site";
              # The current prelude helper still references the removed
              # pkgs.nodePackages set. Keep the provider app-local until that
              # upstream boundary is repaired.
              provider = vercelDeployTarget;
            };
          };
        };
    };
}
