{
  lib,
  theme,
  diagnostics,
}:
let
  inherit (diagnostics)
    combine
    mkDiagnostic
    mkResult
    ;

  inherit (lib)
    attrNames
    concatStringsSep
    elem
    filterAttrs
    mapAttrsToList
    ;

  knownText = concatStringsSep ", " (attrNames theme.themes);

  users =
    model:
    mkResult (
      mapAttrsToList (
        name: user:
        mkDiagnostic {
          severity = "error";
          code = "theme.user.unknown";
          target = name;
          path = [
            "users"
            name
            "theme"
          ];
          message = "User '${name}' chose unknown theme '${user.theme}' (known: ${knownText}).";
        }
      ) (filterAttrs (_: user: !user.known) model.users)
    );

  #
  # The catalogue is repository data, so this holds on every host; it
  # reads the repository, never the store.
  #
  wallpapers =
    _model:
    mkResult (
      mapAttrsToList (
        name: entry:
        mkDiagnostic {
          severity = "error";
          code = "theme.wallpaper.missing";
          target = name;
          path = [
            "themes"
            name
            "wallpaper"
          ];
          message = "Theme '${name}' names wallpaper '${entry.wallpaper}', which is not in _wallpapers.";
        }
      ) (filterAttrs (_: entry: !builtins.pathExists (theme.wallpaperPath entry.wallpaper)) theme.themes)
    );

  iconPack =
    model:
    let
      inherit (model.appearance.icons) pack;
    in
    mkResult (
      lib.optional (!(theme.iconPacks ? ${pack})) (mkDiagnostic {
        severity = "error";
        code = "theme.icons.pack.unknown";
        target = pack;
        path = [
          "appearance"
          "icons"
          "pack"
        ];
        message = "Unknown icon pack '${pack}' (known: ${concatStringsSep ", " (attrNames theme.iconPacks)}).";
      })
    );

  #
  # Packs offer different colours, so a theme's accent may be missing
  # from the host's pack. Its icons keep the pack's own colour.
  #
  iconAccents =
    model:
    let
      pack = theme.iconPacks.${model.appearance.icons.pack} or null;

      accentOf = user: (theme.themes.${user.theme} or { }).iconAccent or null;

      missing = _: user: pack != null && accentOf user != null && !(elem (accentOf user) pack.accents);
    in
    mkResult (
      mapAttrsToList (
        name: user:
        mkDiagnostic {
          severity = "warning";
          code = "theme.icons.accent.unknown";
          target = name;
          path = [
            "users"
            name
            "theme"
          ];
          message = "User '${name}''s theme '${user.theme}' wants icon accent '${accentOf user}', which icon pack '${model.appearance.icons.pack}' lacks (it has: ${concatStringsSep ", " pack.accents}); the pack's own colour is used.";
        }
      ) (filterAttrs missing model.users)
    );

  all =
    model:
    combine [
      (users model)
      (wallpapers model)
      (iconPack model)
      (iconAccents model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    users
    wallpapers
    iconPack
    iconAccents
    all
    ;
}
