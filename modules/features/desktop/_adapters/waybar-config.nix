{ lib }:

#
# The bar for one compositor, as waybar config data: abstract widgets
# are replaced by the compositor's module names, in the layout lists
# and in the settings keys.
#
{ model, compositor }:

let
  resolve = name: compositor.widgets.${name} or name;

  settings = lib.mapAttrs' (name: value: lib.nameValuePair (resolve name) value) model.bar.settings;
in
settings
// {
  modules-left = map resolve model.bar.left;
  modules-center = map resolve model.bar.center;
  modules-right = map resolve model.bar.right;
}
