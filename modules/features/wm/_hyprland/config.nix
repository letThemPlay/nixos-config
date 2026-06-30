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
    "$mod, V, hy3:makefocusedtab, v"
    "$mod, H, hy3:makefocusedtab, h"

    "$mod, left, hy3:movefocus, l"
    "$mod, right, hy3:movefocus, r"
    "$mod, up, hy3:movefocus, u"
    "$mod, down, hy3:movefocus, d"
  ];
}
