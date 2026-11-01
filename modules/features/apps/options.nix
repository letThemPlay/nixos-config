{ config, ... }:
let
  apps = config.flake.features.apps;
in
{
  # Options only.
  flake.nixosModules.apps-options =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.apps = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the apps feature installs and configures the role apps.";
        };

        roles = lib.mapAttrs (
          role: default:
          mkOption {
            type = types.nullOr types.str;
            inherit default;
            description = "App playing the ${role} role, from the catalogue; null for none.";
          }
        ) apps.defaultRoles;

        overrides = mkOption {
          type = types.attrsOf apps.types.override;
          default = { };

          example = {
            browser.command = [
              "firefox"
              "--new-window"
            ];
          };

          description = ''
            Per-role changes to the catalogue entry. Only the fields an
            override defines apply.
          '';
        };

        install = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "git" ];
          description = "Catalogue apps installed and configured without playing a role.";
        };

        dmenuConsumers = mkOption {
          type = types.listOf types.str;
          default = [ ];
          internal = true;
          description = "Components that pick through the launcher's dmenu mode.";
        };

        facts = mkOption {
          type = types.attrsOf apps.types.role;
          readOnly = true;
          description = ''
            Roles resolved: the app's command (wrapped in the terminal
            when needed), app id, package and dmenu command.
          '';
        };

      };
    };
}
