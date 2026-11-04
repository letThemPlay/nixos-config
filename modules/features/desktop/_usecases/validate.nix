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
          message = "Bind '${key}' starts app role '${bind.app}', which is not defined (roles: ${concatStringsSep ", " model.appRoles}).";
        }
      ) (filterAttrs (_: bind: bind.app != null && !(builtins.elem bind.app model.appRoles)) model.binds)

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

  #
  # A profile with no outputs would match a machine with nothing connected, and
  # a scale of zero or less would be refused when it's applied, at plug-in time.
  #
  displays =
    model:
    mkResult (
      mapAttrsToList (
        name: _:
        mkDiagnostic {
          severity = "error";
          code = "desktop.display.profile.outputs.none";
          target = name;
          path = [
            "displays"
            "profiles"
            name
          ];
          message = "Display profile '${name}' has no outputs.";
        }
      ) (filterAttrs (_: profile: profile.outputs == { }) model.displays.profiles)

      ++ concatMap (
        name:
        mapAttrsToList
          (
            criteria: output:
            mkDiagnostic {
              severity = "error";
              code = "desktop.display.outputs.scale";
              target = "${name}.${criteria}";
              path = [
                "displays"
                "profiles"
                name
                "outputs"
                criteria
                "scale"
              ];
              message = "Output '${criteria}' in display profile '${name}' has scale ${toString output.scale}; it must be above 0.";
            }
          )
          (
            filterAttrs (
              _: output: output.scale != null && output.scale <= 0
            ) model.displays.profiles.${name}.outputs
          )
      ) (attrNames model.displays.profiles)
    );

  # wlsunset would only refuse a bad time at login, when the service starts.
  nightLight =
    model:
    let
      valid = time: builtins.match "([01][0-9]|2[0-3]):[0-5][0-9]" time != null;
    in
    mkResult (
      map
        (
          field:
          mkDiagnostic {
            severity = "error";
            code = "desktop.nightLight.time.format";
            target = field;
            path = [
              "nightLight"
              field
            ];
            message = "nightLight.${field} is '${model.nightLight.${field}}'; expected HH:MM.";
          }
        )
        (
          filter (field: !valid model.nightLight.${field}) [
            "from"
            "until"
          ]
        )
    );

  #
  # The shell draws its own widgets, so a name only waybar knows would
  # leave a hole in the bar.
  #
  ui =
    model:
    mkResult (
      lib.optionals (builtins.elem "bar" model.ui.surfaces) (
        map (
          widget:
          mkDiagnostic {
            severity = "error";
            code = "desktop.ui.widget.unknown";
            target = widget;
            path = [ "bar" ];
            message = "Bar widget '${widget}' is not a widget of the unified shell (known: ${concatStringsSep ", " desktop.uiWidgets}).";
          }
        ) (filter (widget: !builtins.elem widget desktop.uiWidgets) (barModules model.bar))
      )
    );

  components =
    model:
    mkResult (
      mapAttrsToList (
        role: component:
        mkDiagnostic {
          severity = "error";
          code = "desktop.component.unknown";
          target = "${role}.${component.name}";
          path = [
            "components"
            role
          ];
          message = "Unknown ${role} component '${component.name}' (known: ${
            concatStringsSep ", " (attrNames (desktop.components.${role} or { }))
          }).";
        }
      ) (filterAttrs (_: component: !component.known) model.components)
    );

  all =
    model:
    combine [
      (components model)
      (displays model)
      (nightLight model)
      (ui model)
      (requirements model)
      (greeter model)
      (idle model)
      (windowRules model)
      (compositors model)
      (binds model)
      (bar model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    compositors
    binds
    bar
    windowRules
    idle
    greeter
    requirements
    displays
    nightLight
    ui
    components
    all
    ;
}
