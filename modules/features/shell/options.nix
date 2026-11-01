{ config, ... }:
let
  shell = config.flake.features.shell;
in
{
  #
  # Options only. Each user's shell comes from ltp.identity; resolving
  # and rendering it happens in normalize and the shell module.
  #
  flake.nixosModules.shell-options =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.shell = {

        enable = mkOption {
          type = types.bool;
          default = true;

          description = ''
            Whether the shell feature sets login shells and renders
            their configuration.
          '';
        };

        defaultAliases = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the default aliases (ll, la) are included.";
        };

        aliases = mkOption {
          type = types.attrsOf types.str;
          default = { };

          example = {
            g = "git";
          };

          description = ''
            Shell-neutral aliases. Features add theirs; every user's
            shell gets them.
          '';
        };

        facts.users = mkOption {
          type = types.attrsOf shell.types.userShell;
          readOnly = true;
          description = "Each enabled user's shell, resolved against the registry.";
        };

      };
    };
}
