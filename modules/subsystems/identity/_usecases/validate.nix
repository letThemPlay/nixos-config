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

  #
  # A signing key must look like a key ID or fingerprint; on a host that
  # signs, a placeholder email makes the signatures unverifiable.
  #
  gpg =
    model:
    let
      signing = filter (user: user.gpg.signingKey != null) (query.all model);

      validKey =
        key:
        builtins.match "(0x)?[0-9A-Fa-f]{16}" key != null || builtins.match "[0-9A-Fa-f]{40}" key != null;

      placeholder = email: builtins.match ".*@(example\\.(com|org|net)|.*\\.invalid)" email != null;
    in
    mkResult (
      map (
        user:
        mkDiagnostic {
          severity = "error";
          code = "identity.user.gpg.signingKey.format";
          target = user.username;
          path = [
            "users"
            user.username
            "gpg"
            "signingKey"
          ];
          message = "User '${user.username}' has signing key '${user.gpg.signingKey}', which is neither a 16-hex key ID nor a 40-hex fingerprint.";
        }
      ) (filter (user: !validKey user.gpg.signingKey) signing)

      ++ lib.optionals model.gpg (
        map (
          user:
          mkDiagnostic {
            severity = "warning";
            code = "identity.user.email.placeholder";
            target = user.username;
            path = [
              "users"
              user.username
              "email"
            ];
            message = "User '${user.username}' signs commits as '${user.email}', a placeholder address; the signatures will not verify against the key.";
          }
        ) (filter (user: placeholder user.email) signing)
      )
    );

  all =
    model:
    combine [
      (gpg model)
      (packages model)
      (features model)
      (users model)
    ];

}
