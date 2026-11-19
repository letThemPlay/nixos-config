{ lib }:
let
  inherit (lib) mkOption types;

  polarity = types.enum [
    "dark"
    "light"
  ];

  size =
    default: description:
    mkOption {
      type = types.ints.positive;
      inherit default description;
    };

  fraction =
    default: description:
    mkOption {
      type = types.numbers.between 0 1;
      inherit default description;
    };

  #
  # A font or cursor: a package attribute path, the name it provides and
  # any extra options.
  #
  packaged =
    package: name: extra:
    mkOption {
      type = types.submodule {
        options = {

          package = mkOption {
            type = types.str;
            default = package;
            description = "Package attribute path in pkgs, e.g. \"nerd-fonts.jetbrains-mono\".";
          };

          name = mkOption {
            type = types.str;
            default = name;
            description = "Name the package provides.";
          };

        }
        // extra;
      };
      default = { };
    };

  # A catalogue entry, one file per theme in _domain/themes.
  theme = types.submodule {
    options = {

      wallpaper = mkOption {
        type = types.str;
        description = "File name in _wallpapers.";
      };

      scheme = mkOption {
        type = types.str;
        description = "base16 scheme name from base16-schemes.";
      };

      polarity = mkOption {
        type = polarity;
        default = "dark";
      };

      iconAccent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Icon colour that follows the theme's accent, from the icon pack's accents; null keeps the pack's own.";
      };

    };
  };

  # Per-host look; the defaults are the values every host had before.
  appearance = types.submodule {
    options = {

      fontSize = {
        terminal = size 11 "Terminal font size.";
        applications = size 12 "Application font size.";
        desktop = size 10 "Desktop (bar, notification) font size.";
      };

      fonts = {
        monospace = packaged "nerd-fonts.jetbrains-mono" "JetBrainsMono Nerd Font" { };

        sansSerif = packaged "dejavu_fonts" "DejaVu Sans" { };

        extra = mkOption {
          type = types.listOf types.str;
          default = [ "nerd-fonts.symbols-only" ];
          description = ''
            Further system fonts, as pkgs attribute paths (icon glyphs
            for the bar and dock).
          '';
        };
      };

      cursor = packaged "bibata-cursors" "Bibata-Modern-Ice" {
        size = size 24 "Cursor size.";
      };

      # Every app's icons, the shell's dock included.
      icons.pack = mkOption {
        type = types.str;
        default = "tela";
        description = "Icon pack from the theme core's registry (tela, papirus); each theme picks its accent.";
      };

      ui = {
        spacing = size 4 "Base spacing unit in pixels; every padding and gap is a multiple of it.";
        radius = size 10 "Corner radius of panels in pixels; controls and cards scale from it.";
        barHeight = size 40 "Height of the top bar's islands in pixels; their widgets sit inside with even padding.";
        animationMs = size 180 "Duration of panel animations in milliseconds.";

        panelOpacity = fraction 0.97 "Opacity of panel backgrounds.";
        scrimOpacity = fraction 0.55 "Opacity of the dim behind modal surfaces.";
        shadowOpacity = fraction 0.25 "Opacity of the soft shadow under panels; 0 for none.";

        iconFont = packaged "material-symbols" "Material Symbols Rounded" { };
      };

    };
  };

  # An icon pack resolved for one user: what to install and the names.
  resolvedIcons = types.submodule {
    options = {

      package = mkOption {
        type = types.str;
        description = "Package attribute path in pkgs.";
      };

      override = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        description = "Arguments to override the package with, e.g. { color = \"indigo\"; }; null for none.";
      };

      dark = mkOption {
        type = types.str;
        description = "Icon theme name for dark themes.";
      };

      light = mkOption {
        type = types.str;
        description = "Icon theme name for light themes.";
      };

    };
  };

  # A user's theme, resolved from the catalogue.
  userTheme = types.submodule {
    options = {

      theme = mkOption {
        type = types.str;
        description = "Theme name the user chose.";
      };

      known = mkOption {
        type = types.bool;
        description = "Whether the theme is in the catalogue.";
      };

      wallpaper = mkOption {
        type = types.nullOr types.path;
        description = "Wallpaper file; null for an unknown theme.";
      };

      scheme = mkOption {
        type = types.nullOr types.str;
      };

      polarity = mkOption {
        type = types.nullOr polarity;
      };

      icons = mkOption {
        type = types.nullOr resolvedIcons;
        description = "The icon pack in the theme's accent; null for an unknown theme or pack.";
      };

    };
  };

  model = types.submodule {
    options = {

      appearance = mkOption {
        type = appearance;
      };

      users = mkOption {
        type = types.attrsOf userTheme;
      };

      ui = mkOption {
        type = types.attrsOf types.anything;
        description = "Design tokens for desktop interfaces.";
      };

    };
  };
in
{
  inherit
    polarity
    theme
    appearance
    userTheme
    model
    ;
}
