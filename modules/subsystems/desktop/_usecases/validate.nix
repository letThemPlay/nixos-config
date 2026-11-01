{
  lib,
  desktop,
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
    concatMap
    concatStringsSep
    filter
    filterAttrs
    mapAttrsToList
    optional
    unique
    ;

  known = model: filter (c: c.known) model.compositors;

  # Abstract widget names: those any registered compositor resolves.
  abstractWidgets = unique (
    concatMap (entry: attrNames entry.widgets) (builtins.attrValues desktop.compositors)
  );

  barModules = bar: bar.left ++ bar.center ++ bar.right;

  # How many of the three bind forms are set.
  setForms =
    bind:
    lib.count (x: x) [
      (bind.spawn != null && bind.spawn != [ ])
      (bind.action != null)
      (bind.app != null)
    ];
in

rec {

  inherit
    mkDiagnostic
    mkResult
    ;

  compositors =
    model:
    mkResult (
      optional (model.compositors == [ ]) (mkDiagnostic {
        severity = "error";
        code = "desktop.compositors.none";
        target = "compositors";
        path = [ "compositors" ];
        message = "No compositor is enabled.";
      })

      ++ map (
        c:
        mkDiagnostic {
          severity = "error";
          code = "desktop.compositor.unknown";
          target = c.name;
          path = [ "compositors" ];
          message = "Unknown compositor '${c.name}' (known: ${concatStringsSep ", " (attrNames desktop.compositors)}).";
        }
      ) (filter (c: !c.known) model.compositors)
    );

  binds =
    model:
    mkResult (
      mapAttrsToList (
        key: _:
        mkDiagnostic {
          severity = "error";
          code = "desktop.bind.invalid";
          target = key;
          path = [
            "binds"
            key
          ];
          message = "Bind '${key}' must set exactly one of spawn (non-empty), action or app.";
        }
      ) (filterAttrs (_: bind: setForms bind != 1) model.binds)

      ++ mapAttrsToList (
        key: bind:
        mkDiagnostic {
          severity = "error";
          code = "desktop.bind.app.unknown";
          target = key;
          path = [
            "binds"
            key
            "app"
          ];
          message = "Bind '${key}' starts app role '${bind.app}', which is not defined (roles: ${concatStringsSep ", " (attrNames model.apps)}).";
        }
      ) (filterAttrs (_: bind: bind.app != null && !(model.apps ? ${bind.app})) model.binds)

      ++ concatMap (
        c:
        let
          entry = desktop.compositors.${c.name};
        in
        mapAttrsToList (
          key: bind:
          mkDiagnostic {
            severity = "error";
            code = "desktop.bind.unsupported";
            target = "${c.name}.${key}";
            path = [
              "binds"
              key
            ];
            message = "Bind '${key}' uses action '${bind.action}', which compositor '${c.name}' does not support.";
          }
        ) (filterAttrs (_: bind: bind.action != null && !(entry.actions ? ${bind.action})) model.binds)
      ) (known model)
    );

  bar =
    model:
    mkResult (
      concatMap (
        c:
        let
          entry = desktop.compositors.${c.name};
        in
        map
          (
            widget:
            mkDiagnostic {
              severity = "error";
              code = "desktop.bar.widget.unsupported";
              target = "${c.name}.${widget}";
              path = [ "bar" ];
              message = "Bar widget '${widget}' has no equivalent in compositor '${c.name}'.";
            }
          )
          (
            filter (widget: builtins.elem widget abstractWidgets && !(entry.widgets ? ${widget})) (
              barModules model.bar
            )
          )
      ) (known model)
    );

  #
  # App roles: the package must exist, and a role run in a terminal
  # needs a terminal role that can run commands.
  #
  apps =
    model:
    let
      terminal = model.apps.terminal or null;

      terminalUsable = terminal != null && terminal.execFlag != null;
    in
    mkResult (
      mapAttrsToList (
        role: app:
        mkDiagnostic {
          severity = "error";
          code = "desktop.app.package.unknown";
          target = role;
          path = [
            "apps"
            role
            "package"
          ];
          message = "App role '${role}' uses package '${app.package}', which is not in pkgs.";
        }
      ) (filterAttrs (_: app: !app.known) model.apps)

      ++ mapAttrsToList (
        role: _:
        mkDiagnostic {
          severity = "error";
          code = "desktop.app.terminal.missing";
          target = role;
          path = [
            "apps"
            role
            "inTerminal"
          ];
          message = "App role '${role}' runs in a terminal, but the terminal role has no execFlag.";
        }
      ) (filterAttrs (_: app: app.inTerminal && !terminalUsable) model.apps)
    );

  #
  # A rule must match something, and every enabled compositor must be
  # able to render the properties it sets.
  #
  windowRules =
    model:
    let
      setProperties = rule: filter (property: rule.${property} != null) desktop.types.ruleProperties;
    in
    mkResult (
      mapAttrsToList (
        name: _:
        mkDiagnostic {
          severity = "error";
          code = "desktop.rule.match.empty";
          target = name;
          path = [
            "windowRules"
            name
            "match"
          ];
          message = "Window rule '${name}' matches no window: set match.appId or match.isActive.";
        }
      ) (filterAttrs (_: rule: rule.match.appId == null && rule.match.isActive == null) model.windowRules)

      ++ concatMap (
        c:
        let
          entry = desktop.compositors.${c.name};
        in
        concatMap (
          name:
          map
            (
              property:
              mkDiagnostic {
                severity = "error";
                code = "desktop.rule.unsupported";
                target = "${c.name}.${name}.${property}";
                path = [
                  "windowRules"
                  name
                  property
                ];
                message = "Window rule '${name}' sets '${property}', which compositor '${c.name}' cannot render.";
              }
            )
            (
              filter (property: !builtins.elem property (entry.ruleProperties or [ ])) (
                setProperties model.windowRules.${name}
              )
            )
        ) (attrNames model.windowRules)
      ) (known model)
    );

  #
  # Suspending at or before the lock time makes the lock step pointless
  # (the session is locked on sleep anyway), so it is almost certainly a
  # mistake.
  #
  idle =
    model:
    let
      inherit (model.idle) lockAfter suspendAfter;
    in
    mkResult (
      optional (lockAfter != null && suspendAfter != null && suspendAfter <= lockAfter) (mkDiagnostic {
        severity = "error";
        code = "desktop.idle.order";
        target = "idle";
        path = [
          "idle"
          "suspendAfter"
        ];
        message = "idle.suspendAfter (${toString suspendAfter}s) must be later than idle.lockAfter (${toString lockAfter}s).";
      })
    );

  greeter =
    model:
    mkResult (
      optional (!model.greeter.known) (mkDiagnostic {
        severity = "error";
        code = "desktop.greeter.unknown";
        target = model.greeter.name;
        path = [ "greeter" ];
        message = "Unknown greeter '${model.greeter.name}' (known: ${concatStringsSep ", " (attrNames desktop.greeters)}).";
      })
    );

  #
  # Requirements name hardware facts. A bind left out for missing
  # hardware is reported, since its key does nothing; a bar widget is
  # left out silently.
  #
  requirements =
    model:
    let
      inherit (model.requirements) known used droppedBinds;
    in
    mkResult (
      lib.optionals (known != null) (
        map (
          fact:
          mkDiagnostic {
            severity = "error";
            code = "desktop.requirement.unknown";
            target = fact;
            path = [ "binds" ];
            message = "Unknown hardware fact '${fact}' in a requirement (known: ${concatStringsSep ", " known}).";
          }
        ) (filter (fact: !builtins.elem fact known) used)
      )

      ++ mapAttrsToList (
        key: requires:
        mkDiagnostic {
          severity = "warning";
          code = "desktop.bind.requirement.missing";
          target = key;
          path = [
            "binds"
            key
          ];
          message = "Bind '${key}' is left out: the host lacks ${concatStringsSep ", " requires}.";
        }
      ) droppedBinds
    );

  # Pickers (clipboard, …) need a launcher that has a dmenu mode.
  dmenu =
    model:
    let
      launcher = model.apps.launcher or null;
    in
    mkResult (
      optional (model.dmenuConsumers != [ ] && (launcher == null || launcher.dmenu == null))
        (mkDiagnostic {
          severity = "error";
          code = "desktop.app.dmenu.missing";
          target = "launcher";
          path = [
            "apps"
            "launcher"
            "dmenu"
          ];
          message = "The launcher role has no dmenu command, which ${concatStringsSep ", " model.dmenuConsumers} needs to pick entries.";
        })
    );

  all =
    model:
    combine [
      (dmenu model)
      (requirements model)
      (greeter model)
      (idle model)
      (windowRules model)
      (compositors model)
      (binds model)
      (apps model)
      (bar model)
    ];

}
