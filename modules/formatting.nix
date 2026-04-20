{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  config.perSystem = _: {
    config = {
      treefmt = {
        programs = {
          deadnix.enable = true;
          keep-sorted.enable = true;
          nixfmt.enable = true;
          shellcheck = {
            enable = true;
            excludes = [ ".envrc" ];
          };
          shfmt.enable = true;
          statix.enable = true;
        };
        settings.excludes = [ "*/hardware_configuration.nix" ];
      };
    };
  };
}
