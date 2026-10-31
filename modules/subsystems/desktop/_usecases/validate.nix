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
      mapAttrsToList
        (
          key: _:
          mkDiagnostic {
            severity = "error";
            code = "desktop.bind.invalid";
            target = key;
            path = [
              "binds"
              key
            ];
            message = "Bind '${key}' must set exactly one of spawn (non-empty) or action.";
          }
        )
        (
          filterAttrs (
            _: bind: (bind.spawn != null && bind.spawn != [ ]) == (bind.action != null)
          ) model.binds
        )

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

  all =
    model:
    combine [
      (compositors model)
      (binds model)
      (bar model)
    ];

}
