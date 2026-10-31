_: {
  flake.nixosModules.alacritty =
    { lib, options, ... }:
    {
      config = lib.mkMerge [
        # Only where the desktop subsystem is present.
        (lib.optionalAttrs (options ? ltp.desktop) {
          ltp.desktop.binds."Mod+Return".spawn = [ "alacritty" ];
        })

        {
          home-manager.sharedModules = [
            (_: {
              programs.alacritty = {
                enable = true;
                settings = {
                  window = {
                    padding = {
                      x = 12;
                      y = 12;
                    };
                    dynamic_padding = true;
                    decorations = "none";
                    startup_mode = "Windowed";
                  };
                  scrolling = {
                    history = 10000;
                  };
                };
              };
              stylix.targets.alacritty.enable = true;
            })
          ];
        }
      ];
    };
}
