{
  config,
  inputs,
  lib,
  ...
}:
{
  config.flake.nixosConfigurations =
    let
      hostsFromDirectory =
        let
          nameFn = lib.replaceStrings [ "_" ] [ "-" ];
          importFn = dir: { imports = [ (inputs.import-tree dir) ]; };
        in
        dir:
        lib.concatMapAttrs (
          name: type:
          if type == "directory" then
            {
              "${nameFn name}" = importFn "${dir}/${name}";
            }
          else
            { }
        ) (builtins.readDir dir);
      hosts = hostsFromDirectory ./by_name;
    in
    lib.mapAttrs (
      name: hostConfig:
      inputs.nixpkgs-nixos.lib.nixosSystem {
        modules = lib.attrValues config.flake.nixosModules ++ [
          inputs.determinate.nixosModules.default
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          hostConfig
          { networking.hostName = name; }
        ];
      }
    ) hosts;
}
