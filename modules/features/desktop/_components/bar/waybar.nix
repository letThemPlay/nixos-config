#
# The status bar: layout and module settings for ltp.desktop.bar, and
# the style. The desktop feature writes one config per compositor
# and starts the matching bar in each session.
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The wireless backend's UI (a pkgs attribute), where the network feature has one.
  wirelessUi = config.ltp.network.facts.wirelessUi;
in
{
  config = {
    ltp.desktop.bar = import ./_waybar/layout.nix {
      inherit lib;
      wirelessUi = if wirelessUi == null then null else lib.getExe pkgs.${wirelessUi};
    };

    # Styled by its own CSS from the theme colours.
    ltp.theme.untargeted = [ "waybar" ];

    home-manager.sharedModules = [
      (_: {
        imports = [ ./_waybar/style.nix ];

        programs.waybar = {
          enable = true;

          # Started per session by the desktop feature.
          systemd.enable = false;
        };
      })
    ];
  };
}
