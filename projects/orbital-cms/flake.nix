{
  description = "Orbital publishing core";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    web-middleware.url = "git+ssh://git@git.s4.gl/straylight/www.git?ref=main&dir=projects/web-middleware";
    web-middleware.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, web-middleware, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
      packageSetFor =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.haskellPackages.override {
          overrides = hself: _hsuper: {
            straylight-web-middleware = hself.callCabal2nix "straylight-web-middleware" web-middleware { };
            orbital-cms = hself.callCabal2nix "orbital-cms" ./. { };
          };
        };
      fullPackageFor = system: (packageSetFor system).orbital-cms;
      packageFor =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.haskell.lib.justStaticExecutables (fullPackageFor system);
      migrationFor =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.writeShellApplication {
          name = "orbital-cms-migrate";
          runtimeInputs = [ pkgs.postgresql_17 ];
          text = ''
            : "''${DATABASE_URL:?DATABASE_URL is required}"
            schema_exists="$(psql -X -A -t "$DATABASE_URL" -c "select to_regclass('cms.schema_migrations') is not null")"
            if [[ "$schema_exists" != "t" ]]; then
              psql -X -v ON_ERROR_STOP=1 "$DATABASE_URL" -f ${./db/migrations/001_initial.sql}
            fi
            migration_exists="$(psql -X -A -t "$DATABASE_URL" -c "select exists(select 1 from cms.schema_migrations where version = 2)")"
            if [[ "$migration_exists" != "t" ]]; then
              psql -X -v ON_ERROR_STOP=1 "$DATABASE_URL" -f ${./db/migrations/002_historical_publication_dates.sql}
            fi
            printf '%s\n' 'orbital-cms: schema is current'
          '';
        };
      importWeylPlanFor =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.writeShellApplication {
          name = "orbital-cms-import-weyl-plan";
          runtimeInputs = [
            pkgs.bun
            pkgs.pandoc
          ];
          text = ''
            exec bun ${./tools/import-weyl-plan.mjs} "$@"
          '';
        };
    in
    {
      packages = forAllSystems (system: {
        default = packageFor system;
        cms = packageFor system;
        migrate = migrationFor system;
        cacert = (pkgsFor system).cacert;
      });

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          package = packageFor system;
          contract = pkgs.runCommand "cms-contract" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
            yq eval '.' ${./contract/openapi.yaml} >/dev/null
            touch $out
          '';
          schema = pkgs.runCommand "cms-schema" { nativeBuildInputs = [ pkgs.postgresql_17 ]; } ''
            export CMS_PGDATA="$TMPDIR/postgres"
            export CMS_SOCKET="$TMPDIR/socket"
            mkdir -p "$CMS_SOCKET"
            initdb --auth=trust --no-locale --encoding=UTF8 -D "$CMS_PGDATA" >/dev/null
            pg_ctl -D "$CMS_PGDATA" -o "-k $CMS_SOCKET" -w start >/dev/null
            trap 'pg_ctl -D "$CMS_PGDATA" -m immediate stop >/dev/null' EXIT
            createdb -h "$CMS_SOCKET" cms_test
            psql -X -v ON_ERROR_STOP=1 -h "$CMS_SOCKET" -d cms_test -f ${./db/migrations/001_initial.sql} >/dev/null
            psql -X -v ON_ERROR_STOP=1 -h "$CMS_SOCKET" -d cms_test -f ${./db/migrations/002_historical_publication_dates.sql} >/dev/null
            psql -X -v ON_ERROR_STOP=1 -h "$CMS_SOCKET" -d cms_test -f ${./db/test/schema.sql} >/dev/null
            touch $out
          '';
          format = pkgs.runCommand "cms-format" { nativeBuildInputs = [ pkgs.haskellPackages.fourmolu ]; } ''
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
          program = "${packageFor system}/bin/orbital-cms";
          meta.description = "Run the Orbital publishing service";
        };
        migrate = {
          type = "app";
          program = "${migrationFor system}/bin/orbital-cms-migrate";
          meta.description = "Apply the Orbital CMS PostgreSQL schema";
        };
        import-weyl-plan = {
          type = "app";
          program = "${importWeylPlanFor system}/bin/orbital-cms-import-weyl-plan";
          meta.description = "Import Weyl .plan articles into Orbital CMS";
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          haskellPackages = packageSetFor system;
        in
        {
          default = haskellPackages.shellFor {
            packages = _: [ haskellPackages.orbital-cms ];
            withHoogle = false;
            nativeBuildInputs = [
              pkgs.cabal-install
              pkgs.postgresql_17
              pkgs.haskellPackages.fourmolu
              pkgs.haskell-language-server
            ];
          };
        }
      );

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-tree);
    };
}
