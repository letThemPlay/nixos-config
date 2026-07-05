_: {
  flake.nixosModules.alacritty = _: {
    config = {
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
