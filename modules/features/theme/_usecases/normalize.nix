{ lib, theme }:

#
# cfg is the ltp.theme option set, or any attrset of the same shape.
# users is the published identity facts as plain data; only each
# user's `theme` is read. No module system is required.
#
{ cfg, users }:

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

      folderColor = entry.folderColor or null;
    }
  ) users;
}
