{
  description = "ORBITAL // FORGE — PureScript source and publishing UI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
      toolchain = pkgs: [
        pkgs.nodejs_24
        pkgs.purescript
      ];
      backendToolchain = pkgs: [
        pkgs.cabal-install
        pkgs.ghc
        pkgs.haskell-language-server
      ];
      backendPackage = pkgs: pkgs.haskellPackages.callCabal2nix "orbital-forge-backend" ./backend { };
      npmApp =
        pkgs: name: command:
        let
          runner = pkgs.writeShellApplication {
            inherit name;
            runtimeInputs = toolchain pkgs;
            text = ''
              if [ ! -x node_modules/.bin/spago ]; then npm ci; fi
              exec npm run ${command} -- "$@"
            '';
          };
        in
        {
          type = "app";
          program = "${runner}/bin/${name}";
        };
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell { packages = toolchain pkgs ++ backendToolchain pkgs; };
        }
      );
      apps = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          backend = backendPackage pkgs;
        in
        {
          default = npmApp pkgs "orbital-forge-check" "check";
          build = npmApp pkgs "orbital-forge-build" "build";
          deploy = npmApp pkgs "orbital-forge-deploy" "deploy";
          backend = {
            type = "app";
            program = "${backend}/bin/orbital-forge-backend";
          };
        }
      );
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          backend = backendPackage pkgs;
        }
      );
      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          backend = backendPackage pkgs;
        }
      );
      nixosModules.default = import ./backend/nixos-module.nix { inherit self; };
      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
