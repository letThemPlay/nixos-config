{ desktop }:

#
# cfg is the ltp.desktop option set, or any attrset of the same shape.
# No module system is required.
#
cfg:

let
  # Defaults are plain data; give them the bind type's full shape.
  defaults = builtins.mapAttrs (
    _: bind:
    {
      spawn = null;
      action = null;
    }
    // bind
  ) desktop.defaultBinds;
in
{
  compositors = map (name: {
    inherit name;
    known = desktop.compositors ? ${name};
  }) cfg.compositors;

  # A component or host bind replaces the default for its key.
  binds = (if cfg.defaultBinds then defaults else { }) // cfg.binds;

  inherit (cfg) bar services keyboard;
}
