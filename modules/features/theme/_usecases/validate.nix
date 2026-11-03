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

  all =
    model:
    combine [
      (users model)
      (wallpapers model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    users
    wallpapers
    all
    ;
}
