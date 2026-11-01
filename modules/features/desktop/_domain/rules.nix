#
# Default window rules. Components add their own through
# ltp.desktop.windowRules; a rule there replaces the default with the
# same name.
#
_: {

  active = {
    match.isActive = true;
    opacity = 1.0;
  };

  inactive = {
    match.isActive = false;
    opacity = 0.85;
  };

}
