_: {
  #
  # The status bar: layout and module settings for ltp.desktop.bar, and
  # the style. The desktop subsystem writes one config per compositor
  # and starts the matching bar in each session.
  #
  flake.nixosModules.waybar =
    { pkgs, ... }:
    {
      config = {
        ltp.desktop.bar = import ./_waybar/layout.nix { inherit pkgs; };

        # Styled by its own CSS from the theme colours.
        ltp.theme.untargeted = [ "waybar" ];

        home-manager.sharedModules = [
          (_: {
            imports = [ ./_waybar/style.nix ];

            programs.waybar = {
              enable = true;

              # Started per session by the desktop subsystem.
              systemd.enable = false;
            };
          })
        ];
      };
    };
}
