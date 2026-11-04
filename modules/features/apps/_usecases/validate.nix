{
  lib,
  apps,
  diagnostics,
}:
let
  inherit (diagnostics)
    combine
    mkDiagnostic
    mkResult
    ;

  inherit (lib)
    attrNames
    concatStringsSep
    filterAttrs
    mapAttrsToList
    optional
    ;

  diagnostic =
    code: path: target: message:
    mkDiagnostic {
      severity = "error";
      inherit
        code
        path
        target
        message
        ;
    };

  each =
    predicate: f: model:
    mapAttrsToList f (filterAttrs (_: predicate) model.roles);

  roles =
    model:
    mkResult (
      each (role: !role.known) (
        name: role:
        diagnostic "apps.app.unknown" [ "roles" name ] role.app
          "The ${name} role names unknown app '${role.app}' (known: ${concatStringsSep ", " (attrNames apps.catalog)})."
      ) model

      ++ each (role: role.known && !role.fits) (
        name: role:
        diagnostic "apps.role.unsupported" [ "roles" name ] role.app
          "App '${role.app}' cannot be the ${name} (it can be: ${
            concatStringsSep ", " apps.catalog.${role.app}.roles
          })."
      ) model

      ++ each (role: !role.packageKnown) (
        name: role:
        diagnostic "apps.package.unknown" [
          "overrides"
          name
          "package"
        ] role.app "The ${name} role uses package '${role.package}', which is not in pkgs."
      ) model
    );

  # A role run in a terminal needs a terminal that can run commands.
  terminal =
    model:
    let
      terminal = model.roles.terminal or null;
      usable = terminal != null && terminal.execFlag != null;
    in
    mkResult (
      each (role: role.inTerminal && !usable) (
        name: _:
        diagnostic "apps.terminal.missing" [
          "roles"
          name
        ] name "The ${name} role runs in a terminal, but the terminal role has no execFlag."
      ) model
    );

  # Installed apps must be in the catalogue, with a package that exists.
  installed =
    model:
    let
      each = predicate: f: mapAttrsToList f (filterAttrs (_: predicate) model.installed);
    in
    mkResult (
      each (app: !app.known) (
        name: _:
        diagnostic "apps.app.unknown" [ "install" ] name
          "Installed app '${name}' is not in the catalogue (known: ${concatStringsSep ", " (attrNames apps.catalog)})."
      )

      ++ each (app: app.known && !app.packageKnown) (
        name: app:
        diagnostic "apps.package.unknown" [
          "install"
        ] name "Installed app '${name}' uses package '${app.package}', which is not in pkgs."
      )
    );

  # Pickers (clipboard, …) need a launcher that has a dmenu mode.
  dmenu =
    model:
    let
      launcher = model.roles.launcher or null;
    in
    mkResult (
      optional (model.dmenuConsumers != [ ] && (launcher == null || launcher.dmenu == null)) (
        diagnostic "apps.dmenu.missing" [ "roles" "launcher" ] "launcher"
          "The launcher role has no dmenu command, which ${concatStringsSep ", " model.dmenuConsumers} needs to pick entries."
      )
    );

  # Without a desktop file there's nothing to open files with.
  handlers =
    model:
    mkResult (
      map (
        role:
        diagnostic "apps.handler.entry.missing" [
          "roles"
          role
        ] role "The ${role} role should open files, but its app has no desktopEntry."
      ) model.handlersMissing
    );

  all =
    model:
    combine [
      (roles model)
      (installed model)
      (terminal model)
      (dmenu model)
      (handlers model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    roles
    terminal
    installed
    dmenu
    handlers
    all
    ;
}
