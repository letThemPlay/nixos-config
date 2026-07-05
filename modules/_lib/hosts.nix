{
  inputs,
  lib,
}:
{
  mkHost =
    {
      hostName,
      architecture,
      stateVersion,
      features ? [ ],
      users ? [ ],
      extraModules ? [ ],
      ...
    }:
    let
      registryData = import (inputs.self + "/modules/features/_registry.nix") {
        inherit inputs;
        lib = inputs.nixpkgs.lib;
      };

      featureRegistryMap = registryData.config.modules.features.registry or { };

      resolvedFeatures = builtins.concatMap (
        name:
        if builtins.hasAttr name featureRegistryMap then
          let
            val = featureRegistryMap.${name};
          in
          if builtins.isList val then
            val
          else if builtins.hasAttr "contents" val then
            val.contents
          else
            [ val ]
        else
          [ ]
      ) features;
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = architecture;
      specialArgs = { inherit inputs; };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        (_: {
          nixpkgs.config.allowUnfreePredicate = _: true;
        })
      ]
      ++ resolvedFeatures
      ++ [
        ({ pkgs, ... }: {
          system.stateVersion = stateVersion;
          networking.hostName = hostName;
          nixpkgs.hostPlatform = lib.mkDefault architecture;

          ltp.hosts.registry.${hostName} = {
            inherit
              hostName
              architecture
              stateVersion
              features
              users
              extraModules
              ;
          };

          users.profiles = lib.genAttrs users (_: {
            enable = true;
          });

          environment.systemPackages = [ pkgs.curl ];
        })

        (import "${inputs.self}/modules/hosts/_hosts/_hardware/${hostName}.nix")
      ]
      ++ extraModules;
    };
}
