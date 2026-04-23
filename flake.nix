{
  description = "REINIT // DX - AI broke it. We fix it.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    purescript-overlay.url = "github:thomashoneyman/purescript-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      purescript-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ purescript-overlay.overlays.default ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            purs
            spago-unstable
            purs-tidy-bin.purs-tidy-0_10_1
            esbuild
            nodejs_22
          ];
        };
      }
    );
}
