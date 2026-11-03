#
# Diagnostics shared by the feature cores' validate use cases. The
# shared kernel: it depends on no feature.
#
# A diagnostic is plain data; mkResult groups a list of them. Each
# feature module turns errors into assertions and warnings into
# warnings, prefixed with its own option path.
#
{ lib, ... }:
let
  inherit (lib)
    concatMap
    filter
    flatten
    groupBy
    mapAttrsToList
    ;

  mkDiagnostic =
    {
      severity,
      code,
      target,
      path ? [ ],
      message,
    }:
    {
      inherit
        severity
        code
        target
        path
        message
        ;
    };

  mkResult =
    diagnostics:

    let
      errors = filter (d: d.severity == "error") diagnostics;

      warnings = filter (d: d.severity == "warning") diagnostics;
    in
    {
      ok = errors == [ ];

      inherit
        diagnostics
        errors
        warnings
        ;

      errorCount = builtins.length errors;
      warningCount = builtins.length warnings;
    };

  # One result holding the diagnostics of several.
  combine = results: mkResult (concatMap (result: result.diagnostics) results);

  # Values that occur more than once.
  duplicateStrings =
    values:

    assert builtins.all builtins.isString values;

    let
      grouped = groupBy (x: x) values;
    in
    flatten (
      mapAttrsToList (value: members: if builtins.length members > 1 then [ value ] else [ ]) grouped
    );
in
{
  ltp.features.diagnostics = {
    inherit
      mkDiagnostic
      mkResult
      combine
      duplicateStrings
      ;
  };
}
