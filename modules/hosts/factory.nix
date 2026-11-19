{
  config,
  inputs,
  lib,
  ...
}:
{
  #
  # Turns one ltp.hosts entry into a nixosConfiguration: every feature
  # (bundles included), the host's bundle and user selection, then the
  # host's own module.
  #
  config.ltp.factory.host =
    hostName: host:
    inputs.nixpkgs.lib.nixosSystem {
      inherit (host) system;

      modules = [
        inputs.home-manager.nixosModules.home-manager
        config.flake.modules.nixos.features
        (_: {
          system.stateVersion = host.stateVersion;
          networking.hostName = hostName;
          networking.hostId = host.hostId;

          nixpkgs.hostPlatform = lib.mkDefault host.system;

          ltp = {
            bundles.selected = host.bundles;

            identity.users = lib.genAttrs host.users (_: {
              enable = true;
            });
          };
        })
        host.module
      ];
    };
}
