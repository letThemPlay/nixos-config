{ config, ... }:
let
  locale = config.flake.subsystems.locale;
in
{
  # Options only.
  flake.nixosModules.locale-api =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.locale = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the locale subsystem sets time zone, language and keyboards.";
        };

        timeZone = mkOption {
          type = types.str;
          default = "Europe/London";
        };

        language = mkOption {
          type = types.str;
          default = "en_GB.UTF-8";
        };

        keyboard = mkOption {
          type = locale.types.keyboard;
          default = { };

          example = {
            console = "uk";
            session = {
              layout = "gb";
              variant = "extd";
            };
          };

          description = ''
            Console (kbd) and session (XKB) keyboards, configured
            separately on purpose.
          '';
        };

      };
    };
}
