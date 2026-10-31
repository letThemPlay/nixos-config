{
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
      features ? [ ],
      users ? [ ],
      extraModules ? [ ],
    }:
    let
      registryData = import (inputs.self + "/modules/features/_registry.nix") {
        inherit inputs;
        lib = inputs.nixpkgs.lib;
      };

      featureRegistry = registryData.config.modules.features.registry;

      unknownFeatures = lib.subtractLists (builtins.attrNames featureRegistry) features;

      resolvedFeatures =
        if unknownFeatures != [ ] then
          throw "host '${hostName}': unknown features ${lib.concatStringsSep ", " unknownFeatures} (known: ${lib.concatStringsSep ", " (builtins.attrNames featureRegistry)})"
        else
          features |> map (featureName: featureRegistry.${featureName}) |> lib.flatten;

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
      ++ resolvedFeatures
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

            # User features are checked against every feature name.
            knownFeatures = builtins.attrNames featureRegistry;
          };

          environment.systemPackages = [ pkgs.curl ];
        })
      ]
      ++ extraModules;
    };
}
