{ lib, apps }:
let
  inherit (lib)
    attrValues
    filterAttrs
    genAttrs
    mapAttrs
    mergeAttrsList
    unique
    ;
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
  entryOf = name: apps.catalog.${name} or null;

  # appDefaults <- catalogue entry <- override. roles and aliases are
  # catalogue-only, not app fields.
  fieldsOf =
    name: override:
    let
      entry = entryOf name;
    in
    apps.types.applyOverride (
      apps.types.appDefaults name
      // removeAttrs (if entry == null then { } else entry) [
        "roles"
        "aliases"
      ]
    ) override;

  # The fields plus what validation needs to know.
  resolveApp =
    name: override:
    let
      fields = fieldsOf name override;
    in
    fields
    // {
      app = name;
      known = entryOf name != null;
      packageKnown = fields.package == null || hasPackage fields.package;
    };

  selected = mapAttrs (
    role: name:
    resolveApp name (cfg.overrides.${role} or { })
    // {
      fits = entryOf name != null && builtins.elem role (entryOf name).roles;
    }
  ) (filterAttrs (_: name: name != null) cfg.roles);

  terminal = selected.terminal or null;

  inUse = unique (map (role: role.app) (attrValues selected) ++ cfg.install);
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

  # Installed apps take the catalogue entry as it is.
  installed = genAttrs cfg.install (name: resolveApp name { });

  aliases = mergeAttrsList (map (name: (entryOf name).aliases or { }) inUse);

  inherit (cfg) dmenuConsumers;
}
