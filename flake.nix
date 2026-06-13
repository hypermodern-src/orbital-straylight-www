{
  description = "straylight.software - the continuity project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The PureScript app on the canonical buck2 build (no spago). Its
    # `…-artifact-straylight-js` package materializes the browser bundle
    # (purs_browser_bundle, STR-242) as a store path we copy into public/ — the
    # buck2 product feeding the Next/MDX shell (STR-236/237). bun2nix still owns
    # the Next/node side; buck2 owns PureScript.
    straylight-web-ps.url = "path:./purescript";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      bun2nix,
      straylight-web-ps,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        bun2nixPkg = bun2nix.packages.${system}.default;

        # The buck2-built browser bundle (straylight.js) as a store path. The PS
        # sub-flake builds it hermetically (purs + esbuild, no spago); we just copy
        # it into public/ before `next build`. This is the spago-kill: PureScript
        # is a buck2 artifact, the root flake never runs purs/spago.
        straylightJs =
          straylight-web-ps.packages.${system}.straylight-prelude-straylight-web-ps-artifact-straylight-js;

        # Hermetic bun dependencies (generate with: bun2nix)
        bunDeps = bun2nixPkg.fetchBunDeps {
          bunNix = ./bun.nix;
        };

        # Haskell API server with OpenAPI specs
        straylight-api = pkgs.haskellPackages.callCabal2nix "straylight-api" ./server { };

        # Production build
        straylight-web = pkgs.stdenv.mkDerivation {
          pname = "straylight-web";
          version = "0.1.0";

          src = ./.;

          nativeBuildInputs = [
            bun2nixPkg.hook
            pkgs.bun
            pkgs.nodejs_22
          ];

          inherit bunDeps;

          bunInstallFlags = [ "--linker=hoisted" ];

          buildPhase = ''
            runHook preBuild

            export PATH="$PWD/node_modules/.bin:$PATH"

            # PureScript bundle: copy the buck2-built straylight.js into public/.
            # No purs/spago here — the bundle is a hermetic store path built by the
            # straylight-web-ps sub-flake (purs_browser_bundle, STR-242/236).
            echo "Staging buck2 straylight.js..."
            install -D -m644 ${straylightJs}/straylight.js public/straylight.js

            # Build Next.js
            echo "Building Next.js..."
            next build

            runHook postBuild
          '';

          installPhase = ''
                        runHook preInstall

                        mkdir -p $out/share/straylight-web
                        cp -r .next/standalone/. $out/share/straylight-web/
                        cp -r .next/static $out/share/straylight-web/.next/
                        cp -r public $out/share/straylight-web/

                        # Create runner script
                        mkdir -p $out/bin
                        cat > $out/bin/straylight-web <<EOF
            #!/usr/bin/env bash
            cd $out/share/straylight-web
            exec ${pkgs.nodejs_22}/bin/node server.js "\$@"
            EOF
                        chmod +x $out/bin/straylight-web

                        runHook postInstall
          '';
        };
      in
      {
        packages = {
          default = straylight-web;
          web = straylight-web;
          api = straylight-api;
        };

        # Checks run by `nix flake check`
        checks = {
          build = straylight-web;
          # PureScript: the buck2 bundle build IS the typecheck (one purs compile
          # over Main + hydrogen + the closure). Gates the spago-free PS path.
          purescript = straylightJs;
        };

        apps.default = {
          type = "app";
          program = "${straylight-web}/bin/straylight-web";
        };

        # Dev runner - runs in current directory. PureScript is built by buck2 in
        # the sub-project's devshell (reflects live edits via `--out`); no spago.
        apps.dev = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "straylight-dev" ''
              set -e
              export PATH="${pkgs.bun}/bin:${pkgs.nodejs_22}/bin:$PWD/node_modules/.bin:$PATH"

              if [ ! -d "node_modules" ]; then
                echo "Installing dependencies..."
                ${pkgs.bun}/bin/bun install
              fi

              echo ""
              echo "// straylight // dev //"
              echo ""
              echo "Building PureScript (buck2)..."
              nix develop ./purescript -c buck2 build //:web --out public/straylight.js

              echo ""
              echo "Starting dev server at http://localhost:3000"
              ${pkgs.bun}/bin/bun run dev
            ''
          );
        };

        # PureScript bundle (buck2, no spago): one `purs compile` + esbuild over
        # Main + hydrogen + the closure, written straight to public/straylight.js.
        apps.purs = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "straylight-purs" ''
              set -e
              echo "Building PureScript bundle (buck2)..."
              nix develop ./purescript -c buck2 build //:web --out public/straylight.js
              echo ""
              echo "Bundle written to public/straylight.js"
              ls -lh public/straylight.js
            ''
          );
        };

        # Root devshell = the Next/node/Haskell side. PureScript has its own
        # buck2 devshell in ./purescript (`nix develop ./purescript`) — no purs or
        # spago here; the bundle is a buck2 product.
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs_22
            pkgs.bun
            pkgs.git
            bun2nixPkg
            # Haskell (API server)
            pkgs.ghc
            pkgs.cabal-install
            pkgs.haskell-language-server
          ];

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"

            echo ""
            echo "// straylight // software //"
            echo ""
            echo "Commands:"
            echo "  bun install           - Install JS dependencies"
            echo "  bun run dev           - Start Next.js dev server"
            echo "  nix run .#purs        - Build PureScript bundle (buck2)"
            echo "  nix run .#dev         - Build + dev (one command)"
            echo "  nix build             - Hermetic production build"
            echo "  nix flake check       - Run all checks"
            echo "  nix develop ./purescript  - PureScript (buck2) devshell"
            echo ""
            echo "Node: $(node --version)"
            echo "Bun: $(bun --version)"
            echo ""
          '';
        };
      }
    );
}
