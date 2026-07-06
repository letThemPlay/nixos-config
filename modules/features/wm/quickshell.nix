_: {
  flake.nixosModules.quickshell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        home-manager.users = lib.mapAttrs (_: _: _: {
          home.packages = [ pkgs.quickshell ];

          xdg.configFile."quickshell".source = ./_quickshell;

          #          programs.niri.settings = {
          #            spawn-at-startup = [
          #              { command = [ "${pkgs.quickshell}/bin/quickshell" ]; }
          #            ];
          #          };
        }) config.ltp.users.registry;
      };
    };
}
