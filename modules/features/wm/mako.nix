_: {
  flake.nixosModules.mako =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.mako;
    in
    {
      options.features.mako.enable = lib.mkEnableOption "Mako Wayland notification daemon" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.mako
        ];

        services.dbus.packages = [ pkgs.mako ];

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

            stylix.targets.mako.enable = true;

            systemd.user.services.mako = {
              Unit = {
                Description = "Mako notification daemon (UWSM Integrated)";
                After = [ "graphical-session.target" ];
                PartOf = [ "graphical-session.target" ];
              };

              Service = {
                ExecStart = "${pkgs.mako}/bin/mako";
                ExecReload = "${pkgs.mako}/bin/makoctl reload";
                Restart = "on-failure";
              };

              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          })
        ];
      };
    };
}
