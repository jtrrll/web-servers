{ inputs, ... }:
{
  config.flake.modules.nixos.portfolio =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.portfolio;
    in
    {
      options = {
        services.portfolio = {
          enable = lib.mkEnableOption "the portfolio service";

          port = lib.mkOption {
            type = lib.types.port;
            default = 8080;
            description = "The port the portfolio server listens on.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.portfolio = {
          description = "Portfolio web server";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            ExecStart = "${
              inputs.portfolio.packages.${pkgs.stdenv.system}.default
            }/bin/server --port ${toString cfg.port}";
            DynamicUser = true;
            Restart = "on-failure";
          };
        };
      };
    };
}
