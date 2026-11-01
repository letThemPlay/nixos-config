{ lib, apps }:
let
  inherit (lib) filterAttrs mapAttrs;
in

#
# cfg is the ltp.apps option set. hasPackage tells whether a pkgs
# attribute path exists; the apps module supplies it. No module system
# is required.
#
{
  cfg,
  hasPackage ? _: true,
}:

let
  # appDefaults <- catalogue entry <- the role's override.
  resolve =
    role: name:
    let
      entry = apps.catalog.${name} or null;

      fields = apps.types.applyOverride (
        apps.types.appDefaults name // removeAttrs (if entry == null then { } else entry) [ "roles" ]
      ) (cfg.overrides.${role} or { });
    in
    fields
    // {
      app = name;
      known = entry != null;
      fits = entry != null && builtins.elem role entry.roles;
      packageKnown = fields.package == null || hasPackage fields.package;
    };

  selected = mapAttrs resolve (filterAttrs (_: name: name != null) cfg.roles);

  terminal = selected.terminal or null;
in
{
  # Apps that run in a terminal are started through the terminal role.
  roles = mapAttrs (
    _: role:
    role
    // {
      command =
        if role.inTerminal && terminal != null && terminal.execFlag != null then
          terminal.command ++ [ terminal.execFlag ] ++ role.command
        else
          role.command;
    }
  ) selected;

  inherit (cfg) dmenuConsumers;
}
