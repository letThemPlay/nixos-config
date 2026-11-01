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

        components = lib.mapAttrs (
          role: default:
          mkOption {
            type = types.nullOr types.str;
            inherit default;
            description = "${role} component, from the component registry; null for none.";
          }
        ) desktop.defaultComponents;

        greeter = mkOption {
          type = types.nullOr types.str;
          default = "tuigreet";

          description = ''
            Login greeter (greetd). It offers the uwsm session of every
            enabled compositor. Null leaves the login to the host.
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

        idle = mkOption {
          type = desktop.types.idle;
          default = { };

          example = {
            lockAfter = 600;
            suspendAfter = null;
          };

          description = ''
            Idle policy: seconds until the session locks and until the
            machine suspends. Null skips that step.
          '';
        };

        defaultWindowRules = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the default window rules (active/inactive opacity) are included.";
        };

        windowRules = mkOption {
          type = types.attrsOf desktop.types.windowRule;
          default = { };

          example = {
            pavucontrol = {
              match.appId = "^pavucontrol$";
              floating = true;
            };
          };

          description = ''
            Window rules by name. Components add theirs; one here
            replaces the default with the same name.
          '';
        };

      };
    };
}
