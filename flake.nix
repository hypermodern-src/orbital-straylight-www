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

    # hydrogen as a first-class library cell — pinned source. Its BUCK is overlaid
    # below (cells.hydrogen) until the BUCK lands in hydrogen itself; this is just
    # the source tree, not a flake.
    hydrogen = {
      url = "git+ssh://git@github.com/straylight-software/hydrogen?ref=main&rev=26f5f4e99217ead6bdd582d23c8d50dcc2eac462";
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
        {
          straylight-prelude.projects.reinit-dx = {
            src = ./.;
            # hydrogen rides in as a buck2 cell (STR-234): consumed as
            # `deps = ["hydrogen//:lib"]` in ./BUCK; the [cells] entry is in
            # .buckconfig; the symlink is materialized by the project mechanism.
            #
            # TEMPORARY: overlay the library BUCK onto the pinned hydrogen source,
            # because hydrogen's own BUCK is not merged yet (READ-only access). Once
            # it is, this becomes `cells.hydrogen = inputs.hydrogen;`.
            cells.hydrogen = pkgs.runCommandLocal "hydrogen-cell" { } ''
              cp -r ${inputs.hydrogen} "$out"
              chmod -R u+w "$out"
              cp ${./nix/hydrogen.BUCK} "$out/BUCK"
            '';
            targets = [ "//:site" ];
            toolchain = {
              # Pure PureScript — no C++ toolchain / clang-tidy gate.
              cxx.enable = false;
              purescript.enable = true;
            };
            # The deployable static site (SSG index.html + reinit.js), pushed to
            # Vercel as a Build-Output-API prebuilt tree:
            #   nix run .#deploy-reinit-dx-site-vercel
            deploy.site.target = "//:site";
          };
        };
    };
}
