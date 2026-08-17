{
  description = "straylight.software - the continuity project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    bun2nix = {
      url = "github:nix-community/bun2nix?ref=2.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      nixpkgs,
      flake-utils,
      bun2nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        bun2nixPkg = bun2nix.packages.${system}.default;
        bunDeps = bun2nixPkg.fetchBunDeps { bunNix = ./bun.nix; };
        projectSource = pkgs.lib.fileset.toSource {
          root = ../..;
          fileset = pkgs.lib.fileset.unions [
            ./.
            ../hydrogen
          ];
        };
        jsToolchain = [
          bun2nixPkg.hook
          pkgs.bun
          pkgs.nodejs_24
        ];
        pursToolchain = jsToolchain ++ [
          pkgs.purescript
          pkgs.git
        ];

        # Spago's lockfile pins every Registry tarball by integrity hash. Fetch
        # that closure once as a fixed-output derivation, then compile with
        # `--offline --pure` below. This keeps Spago canonical without relying
        # on a developer's ambient registry cache or sandbox network access.
        spago-deps = pkgs.stdenvNoCC.mkDerivation {
          pname = "straylight-web-spago-deps";
          version = "0.1.0";
          src = projectSource;
          sourceRoot = "source/projects/straylight-web";
          nativeBuildInputs = pursToolchain ++ [ pkgs.cacert ];
          inherit bunDeps;
          bunInstallFlags = [ "--linker=hoisted" ];

          buildPhase = ''
            runHook preBuild
            export HOME="$TMPDIR/home"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            mkdir -p "$HOME" "$XDG_CACHE_HOME"
            (cd purescript && ${pkgs.nodejs_24}/bin/node ../node_modules/spago/bin/bundle.js fetch --pure)
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            cp -R purescript/.spago $out
            runHook postInstall
          '';

          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-uwLmRdh+S11aroMFjJjxai/HnwSqeQdWDy37KMYr2MY=";
        };

        # Spago is the only PureScript graph. This derivation merely provides
        # the locked JS dependencies and compiler, then invokes that graph.
        straylight-purescript = pkgs.stdenv.mkDerivation {
          pname = "straylight-web-purescript";
          version = "0.1.0";
          src = projectSource;
          sourceRoot = "source/projects/straylight-web";
          nativeBuildInputs = pursToolchain;
          inherit bunDeps;
          bunInstallFlags = [ "--linker=hoisted" ];

          buildPhase = ''
            runHook preBuild
            export PATH="$PWD/node_modules/.bin:${pkgs.nodejs_24}/bin:$PATH"
            export XDG_CACHE_HOME="$TMPDIR/spago-cache"
            mkdir -p purescript/.spago
            cp -R ${spago-deps}/. purescript/.spago/
            chmod -R u+w purescript/.spago
            (cd purescript && ${pkgs.nodejs_24}/bin/node ../node_modules/spago/bin/bundle.js bundle \
              --offline \
              --pure \
              --bundle-type app \
              --platform browser \
              --minify \
              --outfile ../straylight.js \
              --strict)
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            install -D -m644 straylight.js $out/straylight.js
            runHook postInstall
          '';
        };

        straylight-api = pkgs.haskellPackages.callCabal2nix "straylight-api" ./server { };

        straylight-web = pkgs.stdenv.mkDerivation {
          pname = "straylight-web";
          version = "0.1.0";
          src = projectSource;
          sourceRoot = "source/projects/straylight-web";
          nativeBuildInputs = jsToolchain;
          inherit bunDeps;
          bunInstallFlags = [ "--linker=hoisted" ];

          buildPhase = ''
            runHook preBuild
            export PATH="$PWD/node_modules/.bin:${pkgs.nodejs_24}/bin:$PATH"
            install -D -m644 ${straylight-purescript}/straylight.js public/straylight.js
            ${pkgs.nodejs_24}/bin/node node_modules/next/dist/bin/next build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/share/straylight-web
            cp -r .next/standalone/. $out/share/straylight-web/
            cp -r .next/static $out/share/straylight-web/.next/
            cp -r public $out/share/straylight-web/
            mkdir -p $out/bin
            cat > $out/bin/straylight-web <<EOF
            #!/usr/bin/env bash
            cd $out/share/straylight-web
            exec ${pkgs.nodejs_24}/bin/node server.js "\$@"
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
          purescript = straylight-purescript;
          api = straylight-api;
        };

        checks = {
          build = straylight-web;
          purescript = straylight-purescript;
        };

        apps.default = {
          type = "app";
          program = "${straylight-web}/bin/straylight-web";
          meta.description = "Run the production Straylight web server";
        };

        apps.dev = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "straylight-dev" ''
              set -e
              export PATH="${pkgs.bun}/bin:${pkgs.nodejs_24}/bin:$PWD/node_modules/.bin:$PATH"
              if [ ! -d node_modules ]; then
                ${pkgs.bun}/bin/bun install
              fi
              ${pkgs.bun}/bin/bun run build:purs
              exec ${pkgs.bun}/bin/bun run dev
            ''
          );
          meta.description = "Build PureScript with Spago and start Next.js";
        };

        apps.purs = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "straylight-purs" ''
              set -e
              export PATH="${pkgs.bun}/bin:${pkgs.nodejs_24}/bin:$PWD/node_modules/.bin:$PATH"
              if [ ! -d node_modules ]; then
                ${pkgs.bun}/bin/bun install
              fi
              exec ${pkgs.bun}/bin/bun run build:purs
            ''
          );
          meta.description = "Build the Straylight PureScript browser bundle with Spago";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs_24
            pkgs.bun
            pkgs.purescript
            pkgs.git
            bun2nixPkg
            pkgs.ghc
            pkgs.cabal-install
            pkgs.haskell-language-server
          ];

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"
            echo ""
            echo "// straylight // software //"
            echo ""
            echo "  bun run build:purs  - Build the PureScript bundle with Spago"
            echo "  bun run dev         - Start the Next.js dev server"
            echo "  nix run .#dev       - Build PureScript and start Next.js"
            echo "  nix build            - Hermetic production build"
            echo "  nix flake check      - Run all checks"
            echo ""
          '';
        };
      }
    );
}
