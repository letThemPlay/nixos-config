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
      secureBoot ? false,
      tpmUnlock ? false,
      ...
    }:
    let
      registryData = import (inputs.self + "/modules/features/_registry.nix") {
        inherit inputs;
        lib = inputs.nixpkgs.lib;
      };

      resolvedFeatures =
        features
        |> map (featureName: registryData.config.modules.features.registry.${featureName} or [ ])
        |> lib.flatten;

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
          nixpkgs.hostPlatform = lib.mkDefault architecture;

          ltp.boot = {
            enable = true;
            secureBoot.enable = secureBoot;
            tpmUnlock.enable = tpmUnlock;
          };

          ltp.hosts.registry.${hostName} = {
            inherit
              hostName
              architecture
              stateVersion
              features
              users
              extraModules
              secureBoot
              tpmUnlock
              ;
          };

          users.profiles = lib.genAttrs users (_: {
            enable = true;
          });

          environment.systemPackages = [ pkgs.curl ];
        })
      ]
      ++ extraModules;
    };
}
