{ config, ... }:
let
  desktop = config.flake.subsystems.desktop;
in
{
  #
  # Options only. Merging binds and resolving widgets per compositor
  # happen in normalize and the adapters.
  #
  flake.nixosModules.desktop-api =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.desktop = {

        enable = mkOption {
          type = types.bool;
          default = true;

          description = ''
            Whether the desktop subsystem configures the graphical
            session.
          '';
        };

        compositors = mkOption {
          type = types.listOf types.str;
          default = [ "niri" ];

          description = ''
            Compositors offered at login. Each gets its own config, bar
            and binds; sessions pick theirs at runtime.
          '';
        };

        keyboard.layout = mkOption {
          type = types.str;
          default = "gb";
          description = "XKB layout in the graphical session.";
        };

        defaultBinds = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the default window-management binds are included.";
        };

        binds = mkOption {
          type = types.attrsOf desktop.types.bind;
          default = { };

          example = {
            "Mod+Return".spawn = [ "alacritty" ];
            "Mod+Q".action = "close";
          };

          description = ''
            Key binds by key combination. Components add theirs; one
            here replaces the default for that key.
          '';
        };

        bar = mkOption {
          type = desktop.types.bar;
          default = { };
          description = "Status bar layout and module settings.";
        };

        services = mkOption {
          type = types.attrsOf desktop.types.service;
          default = { };
          description = "Background components of the graphical session.";
        };

      };
    };
}
