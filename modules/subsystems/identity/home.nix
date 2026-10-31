{ config, ... }:
let
  identity = config.flake.subsystems.identity;
in
{
  #
  # home-manager wiring for the published users. Separate from the
  # identity module so systems without home-manager can use identity.
  #
  flake.nixosModules.identity-home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      home = identity.home {
        model.users = config.ltp.identity.facts.users;
        inherit (config.system) stateVersion;
      };

      #
      # facts.users is published before validation; an unknown package
      # is reported by the identity assertion, not a missing attribute.
      #
      packagesOf = names: map (name: pkgs.${name}) (builtins.filter (name: pkgs ? ${name}) names);
    in
    {
      config = lib.mkIf config.ltp.identity.enable {
        home-manager.users = lib.mapAttrs (_: user: {
          home = user.home // {
            packages = packagesOf user.home.packages;
          };
        }) home.users;
      };
    };
}
