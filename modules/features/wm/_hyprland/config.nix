{
  "$mod" = "SUPER";

  general = {
    layout = "hy3";
  };

  plugin = {
    hy3 = {
      tabs = {
        height = 15;
        padding = 5;
      };
    };
  };

  bind =
    let
      movewindow = [
        "SUPER_SHIFT, left, hy3:movewindow, left"
        "SUPER_SHIFT, right, hy3:movewindow, right"
        "SUPER_SHIFT, up, hy3:movewindow, up"
        "SUPER_SHIFT, down, hy3:movewindow, down"
      ];
      movefocus = [
        "$mod, left, hy3:movefocus, left"
        "$mod, right, hy3:movefocus, right"
        "$mod, up, hy3:movefocus, up"
        "$mod, down, hy3:movefocus, down"
      ];
      movetoworkspace = [
        "SUPER_SHIFT, 1, hy3:movetoworkspace, 1"
        "SUPER_SHIFT, 2, hy3:movetoworkspace, 2"
        "SUPER_SHIFT, 3, hy3:movetoworkspace, 3"
        "SUPER_SHIFT, 4, hy3:movetoworkspace, 4"
        "SUPER_SHIFT, 5, hy3:movetoworkspace, 5"
        "SUPER_SHIFT, 6, hy3:movetoworkspace, 6"
        "SUPER_SHIFT, 7, hy3:movetoworkspace, 7"
        "SUPER_SHIFT, 8, hy3:movetoworkspace, 8"
        "SUPER_SHIFT, 9, hy3:movetoworkspace, 9"
      ];
      switchtoworkspace = [
        "$mod, 1, hy3:workspace, 1"
        "$mod, 2, hy3:workspace, 2"
        "$mod, 3, hy3:workspace, 3"
        "$mod, 4, hy3:workspace, 4"
        "$mod, 5, hy3:workspace, 5"
        "$mod, 6, hy3:workspace, 6"
        "$mod, 7, hy3:workspace, 7"
        "$mod, 8, hy3:workspace, 8"
        "$mod, 9, hy3:workspace, 9"
      ];
      #      controlbinds = [
      #        ", XF86AudioRaiseVolume, exec, volumectl -u up"
      #        ", XF86AudioLowerVolume, exec, volumectl -u down"
      #        ", XF86AudioMute, exec, volumectl toggle-mute"
      #        ", XF86MonBrightnessUp, exec, lightctl up"
      #        ", XF86MonBrightnessDown, exec, lightctl down"
      #      ];
      generalbinds = [
        "$mod, RETURN, exec, $terminal"
        "$mod, E, exec, $fileManager -w"
        "SUPER_SHIFT, Q, hy3:killactive"
        "$mod, F, fullscreen"
        "SUPER_SHIFT, F, fullscreen, 1"
      ];
    in
    movewindow ++ movefocus ++ movetoworkspace ++ switchtoworkspace ++ generalbinds;
}
