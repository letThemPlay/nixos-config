{
  lib,
  identity,
  diagnostics,
}:
let
  inherit (identity) query;

  inherit (diagnostics)
    combine
    mkDiagnostic
    mkResult
    ;

  inherit (lib)
    concatMap
    filter
    optional
    ;

  #
  # One diagnostic per user value that is not in a known list. A null
  # list means the host has no such catalogue; nothing is checked.
  #
  unknownValues =
    {
      model,
      code,
      field,
      known,
      what,
      values,
    }:
    if known == null then
      [ ]
    else
      concatMap (
        user:
        map (
          value:
          mkDiagnostic {
            severity = "error";
            inherit code;
            target = "${user.username}.${value}";
            path = [
              "users"
              user.username
              field
            ];
            message = "User '${user.username}' names unknown ${what} '${value}'.";
          }
        ) (filter (value: !builtins.elem value known) (values user))
      ) (query.all model);
in

rec {

  inherit
    mkDiagnostic
    mkResult
    ;

  themes =
    model:
    mkResult (unknownValues {
      inherit model;
      code = "identity.user.theme.unknown";
      field = "theme";
      known = model.known.themes;
      what = "theme";
      values = user: [ user.theme ];
    });

  packages =
    model:
    mkResult (unknownValues {
      inherit model;
      code = "identity.user.package.unknown";
      field = "extraPackages";
      known = model.known.packages;
      what = "package";
      values = user: user.extraPackages;
    });

  #
  # User features are checked against every feature any host could
  # include, not this host's: a feature the host lacks is skipped, a
  # misspelt one is an error everywhere.
  #
  features =
    model:
    mkResult (unknownValues {
      inherit model;
      code = "identity.user.feature.unknown";
      field = "features";
      known = model.known.features;
      what = "feature";
      values = user: user.features;
    });

  users =
    model:
    mkResult (
      optional (model.users == { }) (mkDiagnostic {
        severity = "warning";
        code = "identity.users.none";
        target = "users";
        path = [ "users" ];
        message = "No user is enabled on this host.";
      })
    );

  all =
    model:
    combine [
      (themes model)
      (packages model)
      (features model)
      (users model)
    ];

}
