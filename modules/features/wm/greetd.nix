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
              command = ''
                ${pkgs.tuigreet}/bin/tuigreet \
                  --time \
                  --remember \
                  --remember-user \
                  --asterisks \
                  --cmd "uwsm start hyprland-uwsm.desktop"
              '';
              user = "greeter";
            };
          };
        };

        systemd.services.greetd.serviceConfig = lib.mkForce {
          Type = "simple";
          StandardInput = "tty";
          StandardOutput = "tty";
          StandardError = "journal";
          TTYReset = true;
          TTYVHangup = true;
          TTYVTDisallocate = true;
        };
      };
    };
}
