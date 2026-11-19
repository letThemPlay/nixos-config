{
  lib,
  diagnostics,
}:
let
  inherit (diagnostics)
    combine
    mkDiagnostic
    mkResult
    ;

  inherit (lib) concatStringsSep mapAttrsToList;

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

  # Selected names must be in the catalogue.
  selected =
    model:
    mkResult (
      map (
        name:
        diagnostic "bundles.bundle.unknown" [
          "selected"
        ] name "Unknown bundle '${name}' (known: ${concatStringsSep ", " model.known})."
      ) model.unknown
    );

  # A catalogue entry may only require bundles that exist.
  requires =
    model:
    mkResult (
      mapAttrsToList (
        name: missing:
        diagnostic "bundles.requires.unknown" [ "catalog" name "requires" ] name
          "Bundle '${name}' requires unknown bundles ${concatStringsSep ", " missing} (known: ${concatStringsSep ", " model.known})."
      ) model.unknownRequires
    );

  all =
    model:
    combine [
      (selected model)
      (requires model)
    ];
in
{
  inherit selected requires all;
}
