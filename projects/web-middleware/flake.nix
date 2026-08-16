{
  description = "Straylight web middleware policy boundary";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      packageFor =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.haskellPackages.callCabal2nix "straylight-web-middleware" ./. { };
    in
    {
      packages = forAllSystems (system: {
        default = packageFor system;
        middleware = packageFor system;
      });

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          package = packageFor system;
          contract = pkgs.runCommand "web-middleware-contract" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
            yq eval '.' ${./contract/openapi.yaml} >/dev/null
            touch $out
          '';
          format = pkgs.runCommand "web-middleware-format" { nativeBuildInputs = [ pkgs.haskellPackages.fourmolu ]; } ''
            cp -R ${./.} source
            chmod -R u+w source
            cd source
            find app src test -name '*.hs' -print0 | xargs -0 fourmolu --mode check
            touch $out
          '';
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${packageFor system}/bin/straylight-web-middleware";
          meta.description = "Run the Straylight web middleware reference server";
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          haskellPackages = pkgs.haskellPackages;
        in
        {
          default = haskellPackages.shellFor {
            packages = _: [ (packageFor system) ];
            withHoogle = false;
            nativeBuildInputs = [
              pkgs.cabal-install
              haskellPackages.fourmolu
              pkgs.haskell-language-server
            ];
          };
        }
      );

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-tree);
    };
}
