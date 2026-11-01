{ config, lib, ... }:
let
  terminal = lib.concatStringsSep " " config.ltp.apps.facts.terminal.command;
in
{
  config = {
    ltp = {
      desktop = {
        # A soft floating shadow for the launcher.
        windowRules.fuzzel = {
          match.appId = "^fuzzel$";
          shadow = {
            softness = 16;
            color = "rgba(0, 0, 0, 0.65)";
            offset = {
              x = 10;
              y = 10;
            };
          };
          focusRing = true;
        };
      };

      shell.aliases.ff = "fuzzel";
    };

    home-manager.sharedModules = [
      (_: {
        programs.fuzzel = {
          enable = true;

          settings = {
            main = {
              inherit terminal;
              layer = "overlay";
              width = 40;
              horizontal-pad = 20;
              vertical-pad = 15;
              inner-pad = 10;
              line-height = 24;
              fields = "name,generic,comment,exec";
            };
            border = {
              radius = 8;
              width = 0;
            };
          };
        };

      })
    ];
  };
}
