{ config, lib, ... }:
{
  # One nixosConfiguration per ltp.hosts entry (modules/hosts/<name>/).
  flake.nixosConfigurations = lib.mapAttrs config.ltp.factory.host config.ltp.hosts;
}
