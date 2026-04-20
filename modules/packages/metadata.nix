{
  config,
  ...
}:
let
  flakeModule =
    {
      flake-parts-lib,
      ...
    }:
    {
      options.perSystem = flake-parts-lib.mkPerSystemOption (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.packageMetadataChecks;
        in
        {
          options.packageMetadataChecks = {
            enable = lib.mkEnableOption "package metadata checks";
            checks = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
              description = "List of functions (meta -> { success: bool; error: nullable string; }) to validate package metadata";
            };
            packages = lib.mkOption {
              type = lib.types.attrsOf lib.types.package;
              default = config.flake.packages;
              description = "The set of packages to check";
            };
          };

          config.checks.packageMetadata = lib.mkIf cfg.enable (
            let
              checkPackageMetadata =
                { meta, name, ... }:
                let
                  result = lib.pipe cfg.checks [
                    (lib.map (check: {
                      inherit (check meta) success error;
                    }))
                    (lib.filter ({ success, ... }: !success))
                  ];
                in
                if lib.length result == 0 then
                  {
                    success = true;
                    error = null;
                  }
                else
                  {
                    success = false;
                    error = ''
                      Package `${name}` failed the following metadata checks:
                      ${lib.concatMapStringsSep "\n" ({ error, ... }: "- ${error}") result}
                    '';
                  };
              checkFlake = lib.mapAttrsToList (_: checkPackageMetadata) cfg.packages;
              failedPackages = lib.filter (result: !result.success) checkFlake;
            in
            pkgs.runCommand "check-metadata" { } (
              let
                failedCount = lib.length failedPackages;
              in
              if failedCount > 0 then
                throw "\n${toString failedCount} package(s) failed metadata validation:\n${
                  lib.concatMapStringsSep "\n" (result: result.error) failedPackages
                }"
              else
                "echo 'All packages passed metadata validation' > $out"
            )
          );
        }
      );
    };
in
{
  imports = [
    { config.flake.modules.flake.packageMetadataChecks = flakeModule; }
    flakeModule
  ];

  config.perSystem =
    let
      inherit (config.flake.meta) homepage;
    in
    {
      config,
      lib,
      ...
    }:
    {
      config.packageMetadataChecks = {
        enable = true;
        checks = [
          (
            meta:
            if meta ? description then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "A description must be set";
              }
          )
          (
            meta:
            if lib.hasPrefix meta.name (meta.description or "") then
              {
                success = false;
                error = "The description should not repeat the package name";
              }
            else
              {
                success = true;
                error = null;
              }
          )
          (
            meta:
            if
              lib.substring 0 1 (meta.description or "")
              == lib.toUpper (lib.substring 0 1 (meta.description or ""))
            then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "The first word of the description should be capitalized";
              }
          )
          (
            meta:
            if lib.hasInfix "\n" (meta.description or "") then
              {
                success = false;
                error = "The description should not contain newlines";
              }
            else
              {
                success = true;
                error = null;
              }
          )
          (
            meta:
            if lib.hasSuffix "." (meta.description or "") then
              {
                success = false;
                error = "The description should not end with punctuation";
              }
            else
              {
                success = true;
                error = null;
              }
          )
          (
            meta:
            if meta ? homepage then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "A homepage must be set";
              }
          )
          (
            meta:
            if (meta.homepage or "") == homepage then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "The homepage must be ${homepage}";
              }
          )
          (
            meta:
            if meta ? license then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "A license must be set";
              }
          )
          (
            meta:
            if meta.license.free or false then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "The license must be free";
              }
          )
          (
            meta:
            if meta ? maintainers then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "The maintainers must be set";
              }
          )
          (
            meta:
            if lib.isList (meta.maintainers or [ ]) then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "The maintainers must be a list";
              }
          )
          (
            meta:
            if (lib.length (meta.maintainers or [ ])) > 0 then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "At least one maintainer must be set";
              }
          )
          (
            meta:
            if meta ? platforms then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "The supported platforms must be set";
              }
          )
          (
            meta:
            if lib.isList (meta.platforms or [ ]) then
              {
                success = true;
                error = null;
              }
            else
              {
                success = false;
                error = "The supported platforms must be a list";
              }
          )
        ];
        packages = lib.filterAttrs (name: _: !lib.hasPrefix "devenv" name) config.packages;
      };
    };
}
