_: {
  flake.nixosModules.greetd =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      waylandSessionsDir = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
    in
    {
      config = {
        services.greetd = {
          enable = true;

          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --remember --remember-session --sessions ${waylandSessionsDir} exec uwsm start --";
              user = "greeter";
            };
          };

          useTextGreeter = true;
        };

        systemd.tmpfiles.rules = [
          "d /var/cache/tuigreet 0755 greeter greeter -"
        ];

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
