_: {
  flake.nixosModules.mako =
    { pkgs, ... }:
    let
      makoctl = "${pkgs.mako}/bin/makoctl";
    in
    {
      config = {
        environment.systemPackages = [
          pkgs.mako
        ];

        services.dbus.packages = [ pkgs.mako ];

        ltp.desktop = {
          services.mako = {
            description = "Mako notification daemon";
            exec = [ "${pkgs.mako}/bin/mako" ];
          };

          binds = {
            "Mod+Escape".spawn = [
              makoctl
              "dismiss"
            ];

            "Mod+Shift+Escape".spawn = [
              makoctl
              "dismiss"
              "--all"
            ];
          };
        };

        home-manager.sharedModules = [
          (_: {
            services.mako = {
              enable = true;

              settings = {
                layer = "overlay";
                anchor = "top-right";
                margin = "12,12";
                padding = "15";
                "border-size" = 2;
                "border-radius" = 8;
                "default-timeout" = 5000;
                "group-by" = "category";
                "max-icon-size" = 48;
              };
            };

          })
        ];
      };
    };
}
