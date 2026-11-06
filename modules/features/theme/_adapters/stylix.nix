{ lib }:

#
# Per-user stylix settings as plain data. Package attribute paths and
# scheme names are resolved against pkgs by the stylix module. Users
# with an unknown theme are left out; validation reports them.
#
{ model }:

let
  inherit (model) appearance;
in
{
  users = lib.mapAttrs (_: user: {
    inherit (user) polarity scheme;

    image = user.wallpaper;

    fonts = {
      sizes = {
        inherit (appearance.fontSize) terminal applications desktop;
      };

      inherit (appearance.fonts) monospace sansSerif;
    };

    cursor = {
      inherit (appearance.cursor) package name size;
    };

    inherit (user) icons;
  }) (lib.filterAttrs (_: user: user.known) model.users);
}
