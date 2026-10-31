_: {
  flake.nixosModules.fuzzel =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      terminal = lib.concatStringsSep " " config.ltp.desktop.facts.apps.terminal.command;
    in
    {
      config = {
        ltp.desktop.binds."Mod+D".spawn = [ "${pkgs.fuzzel}/bin/fuzzel" ];

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

            stylix.targets.fuzzel.enable = true;
          })
        ];
      };
    };
}
