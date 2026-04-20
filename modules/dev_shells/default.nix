{
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.devenv.flakeModule ];

  config.perSystem =
    let
      shellsFromDirectory =
        let
          nameFn = lib.replaceStrings [ "_" ] [ "-" ];
          importFn = import;
        in
        directory:
        lib.concatMapAttrs (
          name: type:
          let
            path = directory + "/${name}";
          in
          if type == "directory" then
            { "${nameFn name}" = importFn "${path}/shell.nix"; }
          else if type == "regular" && lib.hasSuffix ".nix" name then
            { "${nameFn (lib.removeSuffix ".nix" name)}" = importFn path; }
          else
            { }
        ) (builtins.readDir directory);
    in
    {
      config.devenv = {
        modules = [
          {
            containers = lib.mkForce { }; # Workaround to remove containers from flake checks.
          }
        ];
        shells = shellsFromDirectory ./by_name;
      };
    };
}
