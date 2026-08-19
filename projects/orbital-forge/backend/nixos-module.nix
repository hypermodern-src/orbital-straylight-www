{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.orbital-forge-backend;
in
{
  options.services.orbital-forge-backend = {
    enable = lib.mkEnableOption "the ORBITAL // FORGE Haskell backend";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.backend;
      defaultText = lib.literalExpression "orbital-forge.packages.\${pkgs.system}.backend";
      description = "Backend package to run.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which Warp listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3210;
      description = "Loopback port on which Warp listens.";
    };

    upstreamBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:3200/api/v1";
      description = "Forgejo API base used by the initial provider adapter.";
    };

    organization = lib.mkOption {
      type = lib.types.str;
      default = "straylight";
      description = "Only Forgejo organization the read proxy is allowed to expose.";
    };

    allowedOrigins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional exact browser origins allowed by CORS.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional credential file containing FORGEJO_TOKEN.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.orbital-forge-backend = {
      description = "ORBITAL // FORGE Haskell backend";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "forgejo.service"
      ];
      wants = [ "forgejo.service" ];
      environment = {
        HOST = cfg.host;
        PORT = toString cfg.port;
        FORGEJO_BASE_URL = cfg.upstreamBaseUrl;
        FORGEJO_ORGANIZATION = cfg.organization;
        FORGE_CORS_ORIGINS = lib.concatStringsSep "," cfg.allowedOrigins;
      };
      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = "2s";
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      }
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
    };
  };
}
