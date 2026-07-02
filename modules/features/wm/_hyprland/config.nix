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

  bind = [
    "$mod, Return, exec, alacritty"
    "$mod, Q, killactive"
    "$mod, M, exit"
  ];

  extraConfig = ''
    plugin:hy3 {
      # Custom plugin-specific keybindings (Evaluated strictly AFTER hy3 mounts into memory)
      bind = $mod, V, hy3:makefocusedtab, v
      bind = $mod, H, hy3:makefocusedtab, h

      bind = $mod, left, hy3:movefocus, l
      bind = $mod, right, hy3:movefocus, r
      bind = $mod, up, hy3:movefocus, u
      bind = $mod, down, hy3:movefocus, d
    }
  '';
}
