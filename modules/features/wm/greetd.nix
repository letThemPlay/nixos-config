_: {
  flake.nixosModules.greetd =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.greetd;
    in
    {
      options.features.greetd.enable =
        lib.mkEnableOption "Greetd login manager with tuigreet frontend"
        // {
          default = false;
        };

      config = lib.mkIf cfg.enable {
        services.greetd = {
          enable = true;

          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --cmd uswm start hyprland-uwsm.desktop";
              user = "greeter";
            };
          };

          useTextGreeter = true;
        };

        systemd.services.greetd = {
          after = [ "display-manager.service" ];
          wants = [ "display-manager.service" ];

          serviceConfig = {
            Type = lib.mkForce "simple";
            StandardInput = "tty";
            StandardOutput = "tty";
            StandardError = "journal";
            TTYReset = true;
            TTYVHangup = true;
            TTYVTDisallocate = true;
          };
        };
      };
    };
}
