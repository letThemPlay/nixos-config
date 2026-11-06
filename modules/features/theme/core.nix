#
# The theme core, laid out like the storage core:
#
#   _domain/      entities: theme, appearance and model types; the
#                 catalogue, one file per theme in themes/; colour roles;
#                 icon folder colours
#   _wallpapers/  wallpaper files the catalogue names
#   _usecases/    normalize (host settings + identity facts -> model),
#                 validate, ui-tokens (appearance -> design tokens)
#   _adapters/    model -> per-user stylix settings
#
# options.nix, module.nix and stylix.nix beside this file are the outer
# ring.
#
# Each file is a plain function; `theme` is the assembled core.
#
{
  config,
  lib,
  ...
}:
let
  inherit (config.ltp.features) diagnostics;
  inherit (config.ltp.lib) findFilesWithExt;
in
{
  ltp.features.theme = lib.fix (theme: {

    types = import ./_domain/types.nix { inherit lib; };

    # Catalogue: theme name (file name) -> entry.
    themes = lib.listToAttrs (
      map (file: lib.nameValuePair (lib.removeSuffix ".nix" (baseNameOf file)) (import file)) (
        findFilesWithExt "nix" ./_domain/themes
      )
    );

    wallpaperPath = file: ./_wallpapers + "/${file}";

    # Folder colours a theme can name.
    folderColors = import ./_domain/folder-colors.nix { };

    # Colour role -> base16 slot, for anything drawing an interface.
    uiPalette = import ./_domain/ui-palette.nix { };

    uiTokens = import ./_usecases/ui-tokens.nix { inherit theme; };

    normalize = import ./_usecases/normalize.nix { inherit lib theme; };

    validate = import ./_usecases/validate.nix { inherit lib theme diagnostics; };

    stylix = import ./_adapters/stylix.nix { inherit lib; };

  });

  # Present on every host; bundles and host settings decide what it does.
  flake.modules.nixos.features.imports = [
    config.flake.nixosModules.theme-options
    config.flake.nixosModules.theme
    config.flake.nixosModules.theme-stylix
  ];
}
