{
  description = "ORBITAL // FORGE — PureScript source and publishing UI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
      toolchain = pkgs: [ pkgs.nodejs_24 pkgs.purescript ];
      npmApp = pkgs: name: command:
        let runner = pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = toolchain pkgs;
          text = ''
            if [ ! -x node_modules/.bin/spago ]; then npm ci; fi
            exec npm run ${command} -- "$@"
          '';
        };
        in { type = "app"; program = "${runner}/bin/${name}"; };
    in {
      devShells = forAllSystems (system:
        let pkgs = pkgsFor system;
        in { default = pkgs.mkShell { packages = toolchain pkgs; }; });
      apps = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          default = npmApp pkgs "orbital-forge-check" "check";
          build = npmApp pkgs "orbital-forge-build" "build";
          deploy = npmApp pkgs "orbital-forge-deploy" "deploy";
        });
      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
