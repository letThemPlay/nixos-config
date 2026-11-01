#
# The theme core, laid out like the storage core:
#
#   _domain/      entities: theme, appearance and model types; the
#                 catalogue, one file per theme in themes/
#   _wallpapers/  wallpaper files the catalogue names
#   _usecases/    normalize (host settings + identity facts -> model),
#                 validate
#   _adapters/    model -> per-user stylix settings
#
# api.nix, module.nix and stylix.nix beside this file are the outer
# ring.
#
# Each file is a plain function; `theme` is the assembled core.
#
{
  config,
  lib,
  findFilesWithExt,
  ...
}:
let
  inherit (config.flake.features) diagnostics;
in
{
  flake.features.theme = lib.fix (theme: {

    types = import ./_domain/types.nix { inherit lib; };

    # Catalogue: theme name (file name) -> entry.
    themes = lib.listToAttrs (
      map (file: lib.nameValuePair (lib.removeSuffix ".nix" (baseNameOf file)) (import file)) (
        findFilesWithExt "nix" ./_domain/themes
      )
    );

    wallpaperPath = file: ./_wallpapers + "/${file}";

    normalize = import ./_usecases/normalize.nix { inherit lib theme; };

    validate = import ./_usecases/validate.nix { inherit lib theme diagnostics; };

    stylix = import ./_adapters/stylix.nix { inherit lib; };

  });
}
