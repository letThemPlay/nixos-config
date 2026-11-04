{ theme }:

#
# The design tokens every desktop interface shares, from the host's
# appearance: a colour-role map (resolved per user, as schemes are per
# user), and one scale each for spacing, corners, type, icons and motion.
# Interfaces take their measures from here instead of choosing their own.
#
{ appearance }:

let
  inherit (appearance) fontSize fonts ui;

  unit = ui.spacing;
in
{
  palette = theme.uiPalette;

  opacity = {
    panel = ui.panelOpacity;
    scrim = ui.scrimOpacity;
  };

  space = {
    xs = unit;
    sm = unit * 2;
    md = unit * 3;
    lg = unit * 4;
    xl = unit * 6;
  };

  radius = {
    sm = ui.radius / 2;
    md = ui.radius * 4 / 5;
    lg = ui.radius;
  };

  size = {
    bar = ui.barHeight;
    barItem = ui.barHeight - unit * 3;
    launcher = unit * 160;
    sidePanel = unit * 100;
    field = unit * 13;
  };

  font = {
    family = fonts.sansSerif.name;
    monospace = fonts.monospace.name;

    small = fontSize.desktop - 1;
    body = fontSize.desktop;
    title = fontSize.desktop + 2;
    heading = fontSize.desktop + 6;
    display = fontSize.desktop * 6;
  };

  icon = {
    inherit (ui.iconFont) package name;

    small = unit * 4;
    medium = unit * 5;
    large = unit * 8;
    huge = unit * 12;

    theme = ui.iconTheme;
  };

  motion = {
    fast = ui.animationMs / 2;
    normal = ui.animationMs;
  };
}
