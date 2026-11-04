{ config, ... }:
let
  theme = config.ltp.features.theme;
in
{
  #
  # Options only. Resolving each user's theme is a domain rule and
  # happens in normalize.
  #
  flake.nixosModules.theme-options =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.theme = {

        enable = mkOption {
          type = types.bool;
          default = true;

          description = ''
            Whether the theme feature themes the users' desktops.
          '';
        };

        appearance = mkOption {
          type = theme.types.appearance;
          default = { };

          example = {
            fontSize.terminal = 14;
            cursor.size = 32;
          };

          description = ''
            Host-specific look: font sizes, font families and cursor.
          '';
        };

        untargeted = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "waybar" ];
          description = ''
            Programs that style themselves from the theme's colours, so
            the theme backend leaves them alone. Every other program
            the backend knows is themed automatically.
          '';
        };

        facts.users = mkOption {
          type = types.attrsOf theme.types.userTheme;
          readOnly = true;

          description = ''
            Each enabled user's theme resolved from the catalogue.
            Features read wallpapers and polarity from here.
          '';
        };

        facts.ui = mkOption {
          type = types.attrsOf types.anything;
          readOnly = true;

          description = ''
            Design tokens for desktop interfaces: colour roles as base16
            slots, and the spacing, corner, type, icon and motion scales.
          '';
        };

      };
    };
}
