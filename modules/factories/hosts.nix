{
  config,
  inputs,
  lib,
  ...
}:
{
  #
  # Turns one ltp.hosts entry into a nixosConfiguration: every
  # feature, the chosen bundles' settings, then the host's own module.
  #
  config.ltp.factory.host =
    hostName: host:
    let
      bundleRegistry = config.ltp.bundles;

      unknownBundles = lib.subtractLists (builtins.attrNames bundleRegistry) host.bundles;

      resolvedBundles =
        if unknownBundles != [ ] then
          throw "host '${hostName}': unknown bundles ${lib.concatStringsSep ", " unknownBundles} (known: ${lib.concatStringsSep ", " (builtins.attrNames bundleRegistry)})"
        else
          map (name: bundleRegistry.${name}.module) host.bundles;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (host) system;

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
        (
          { pkgs, ... }:
          {
            system.stateVersion = host.stateVersion;
            networking.hostName = hostName;
            networking.hostId = "deadbeef";

            nixpkgs.hostPlatform = lib.mkDefault host.system;

            ltp.identity = {
              users = lib.genAttrs host.users (_: {
                enable = true;
              });

              # User bundles are checked against every bundle name.
              knownBundles = builtins.attrNames bundleRegistry;
            };

            environment.systemPackages = [ pkgs.curl ];
          }
        )
        host.module
      ];
    };
}
