_: {
  flake.nixosModules.alacritty =
    { config, lib, ... }:
    let
      cfg = config.features.alacritty;
    in
    {
      options.features.alacritty.enable =
        lib.mkEnableOption "Alacritty GPU-accelerated terminal emulator"
        // {
          default = false;
        };

      config = lib.mkIf cfg.enable {
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
      };
    };
}
