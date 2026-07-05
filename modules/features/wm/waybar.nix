_: {
  flake.nixosModules.waybar =
    {
      pkgs,
      ...
    }:
    {
      config = {
        home-manager.sharedModules = [
          (_: {
            programs.waybar = {
              enable = true;

              systemd = {
                enable = true;
                targets = [ "graphical-session.target" ];
              };

              settings = {
                mainBar = import ./_waybar/layout.nix { inherit pkgs; };
              };

              style = import ./_waybar/style.nix;
            };
          })
        ];
      };
    };
}
