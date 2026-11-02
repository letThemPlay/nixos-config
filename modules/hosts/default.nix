{ config, lib, ... }:
{
  # One nixosConfiguration per flake.hosts entry (modules/hosts/<name>/).
  flake.nixosConfigurations = lib.mapAttrs config.flake.factory.host config.flake.hosts;
}
