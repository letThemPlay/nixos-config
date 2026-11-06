{ lib, theme }:

#
# cfg is the ltp.theme option set, or any attrset of the same shape.
# users is the published identity facts as plain data; only each
# user's `theme` is read. No module system is required.
#
{ cfg, users }:

let
  pack = theme.iconPacks.${cfg.appearance.icons.pack} or null;

  #
  # The host's icon pack in a theme's accent. An accent the pack lacks
  # falls back to the pack's own colour; validation warns about it.
  #
  iconsFor =
    entry:
    let
      wanted = entry.iconAccent or null;
      accent = if pack != null && lib.elem wanted pack.accents then wanted else null;
      nameFor = polarity: pack.name { inherit accent polarity; };
    in
    if entry == null || pack == null then
      null
    else
      {
        inherit (pack) package;
        override = if accent != null && pack.override != null then { ${pack.override} = accent; } else null;
        dark = nameFor "dark";
        light = nameFor "light";
      };
in
{
  inherit (cfg) appearance;

  ui = theme.uiTokens { inherit (cfg) appearance; };

  users = lib.mapAttrs (
    _: user:
    let
      entry = theme.themes.${user.theme} or null;
    in
    {
      inherit (user) theme;

      known = entry != null;

      wallpaper = if entry == null then null else theme.wallpaperPath entry.wallpaper;

      scheme = entry.scheme or null;

      polarity = entry.polarity or null;

      icons = iconsFor entry;
    }
  ) users;
}
