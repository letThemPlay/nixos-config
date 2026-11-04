{ lib, apps }:
let
  inherit (lib)
    attrNames
    attrValues
    filterAttrs
    genAttrs
    mapAttrs
    mapAttrsToList
    mergeAttrsList
    optionalAttrs
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

  defaultHandlers = cfg.defaultHandlers or false;

  # The roles in use that open files.
  handling = filterAttrs (role: _: apps.mimeTypes ? ${role}) selected;

  #
  # xdg-open ignores Terminal=true, so an app's own desktop file would start it
  # with no terminal and it would die. These open in the terminal role instead,
  # through a generated file that every opener handles the same.
  #
  throughTerminal =
    if terminal != null && terminal.execFlag != null then
      filterAttrs (_: app: app.opensInTerminal && app.desktopEntry != null) handling
    else
      { };

  handlerName = app: "ltp-${app.app}";

  handlerFile =
    role: app: if throughTerminal ? ${role} then "${handlerName app}.desktop" else app.desktopEntry;
in
{
  inherit defaultHandlers;

  handlers =
    if defaultHandlers then
      mergeAttrsList (
        mapAttrsToList (
          role: app:
          optionalAttrs (app.desktopEntry != null) (
            genAttrs apps.mimeTypes.${role} (_: [ (handlerFile role app) ])
          )
        ) handling
      )
    else
      { };

  handlerEntries =
    if defaultHandlers then
      lib.mapAttrs' (
        role: app:
        lib.nameValuePair (handlerName app) {
          name = app.app;
          exec = lib.concatStringsSep " " (
            terminal.command ++ [ terminal.execFlag ] ++ app.command ++ [ "%F" ]
          );
          terminal = false;
          # Only for opening files: the launcher already lists the app itself.
          noDisplay = true;
          mimeType = apps.mimeTypes.${role};
        }
      ) throughTerminal
    else
      { };

  handlersMissing =
    if defaultHandlers then
      attrNames (filterAttrs (_: app: app.desktopEntry == null) handling)
    else
      [ ];

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
