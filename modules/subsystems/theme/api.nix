{ config, ... }:
let
  theme = config.flake.subsystems.theme;
in
{
  #
  # Options only. Resolving each user's theme is a domain rule and
  # happens in normalize.
  #
  flake.nixosModules.theme-api =
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
            Whether the theme subsystem themes the users' desktops.
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

        facts.users = mkOption {
          type = types.attrsOf theme.types.userTheme;
          readOnly = true;

          description = ''
            Each enabled user's theme resolved from the catalogue.
            Features read wallpapers and polarity from here.
          '';
        };

      };
    };
}
