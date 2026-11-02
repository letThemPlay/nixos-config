{
  config,
  inputs,
  lib,
  ...
}:
{
  config.flake.factory.host =
    {
      hostName,
      architecture,
      stateVersion,
      bundles ? [ ],
      users ? [ ],
      extraModules ? [ ],
    }:
    let
      bundleRegistry = config.flake.bundles;

      unknownBundles = lib.subtractLists (builtins.attrNames bundleRegistry) bundles;

      resolvedBundles =
        if unknownBundles != [ ] then
          throw "host '${hostName}': unknown bundles ${lib.concatStringsSep ", " unknownBundles} (known: ${lib.concatStringsSep ", " (builtins.attrNames bundleRegistry)})"
        else
          map (name: bundleRegistry.${name}.module) bundles;

      hardwarePath = inputs.self + "/modules/hosts/_hosts/_hardware/${hostName}.nix";

      resolvedHardware = if builtins.pathExists hardwarePath then import hardwarePath else { };

    in
    inputs.nixpkgs.lib.nixosSystem {
      system = architecture;
      modules = [
        inputs.home-manager.nixosModules.home-manager
        (_: {
          nixpkgs.config.allowUnfreePredicate = _: true;
        })
      ]
      # Every feature, then the settings of the chosen bundles.
      ++ [ config.flake.modules.nixos.features ]
      ++ resolvedBundles
      ++ [
        resolvedHardware
        ({ pkgs, ... }: {
          system.stateVersion = stateVersion;
          networking.hostName = hostName;
          networking.hostId = "deadbeef";

          nixpkgs.hostPlatform = lib.mkDefault architecture;

          ltp.identity = {
            users = lib.genAttrs users (_: {
              enable = true;
            });

            # User bundles are checked against every bundle name.
            knownBundles = builtins.attrNames bundleRegistry;
          };

          environment.systemPackages = [ pkgs.curl ];
        })
      ]
      ++ extraModules;
    };
}
