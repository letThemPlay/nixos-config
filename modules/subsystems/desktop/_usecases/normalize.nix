{ lib, desktop }:
let
  inherit (lib)
    attrNames
    filterAttrs
    genAttrs
    mapAttrs
    unique
    ;

  # An override only replaces the fields it sets.
  setFields = filterAttrs (_: value: value != null);
in

#
# cfg is the ltp.desktop option set, or any attrset of the same shape.
# hasPackage tells whether a pkgs attribute path exists; the desktop
# module supplies it. No module system is required.
#
{
  cfg,
  hasPackage ? _: true,
}:

let
  # appDefaults <- default role <- override.
  roles = genAttrs (unique (attrNames desktop.defaultApps ++ attrNames cfg.apps)) (
    role:
    desktop.types.appDefaults role
    // (desktop.defaultApps.${role} or { })
    // setFields (cfg.apps.${role} or { })
  );

  terminal = roles.terminal or null;

  # Apps that run in a terminal are started through the terminal role.
  apps = mapAttrs (
    _: app:
    app
    // {
      known = hasPackage app.package;

      command =
        if app.inTerminal && terminal != null && terminal.execFlag != null then
          terminal.command ++ [ terminal.execFlag ] ++ app.command
        else
          app.command;
    }
  ) roles;

  # Plain-data binds get the bind type's full shape.
  shape =
    bind:
    {
      spawn = null;
      action = null;
      app = null;
    }
    // bind;

  merged = mapAttrs (_: shape) (
    (if cfg.defaultBinds then desktop.defaultBinds else { }) // cfg.binds
  );
in
{
  compositors = map (name: {
    inherit name;
    known = desktop.compositors ? ${name};
  }) cfg.compositors;

  inherit apps;

  # A component or host bind replaces the default for its key; command
  # is the final argv of a spawn or app bind.
  binds = mapAttrs (
    _: bind:
    bind
    // {
      command =
        if bind.spawn != null then
          bind.spawn
        else if bind.app != null && apps ? ${bind.app} then
          apps.${bind.app}.command
        else
          null;
    }
  ) merged;

  inherit (cfg) bar services keyboard;
}
