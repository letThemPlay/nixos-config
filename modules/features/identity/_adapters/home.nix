{ lib }:

#
# home-manager.users.<name>.home as plain data. Packages are names; the
# identity-home module resolves them from pkgs.
#
{ model, stateVersion }:

{
  users = lib.mapAttrs (_: user: {
    home = {
      inherit (user) username;

      inherit stateVersion;

      packages = user.extraPackages;
    };
  }) model.users;
}
