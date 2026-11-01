{
  lib,
  nix,
  diagnostics,
}:
let
  inherit (diagnostics)
    combine
    duplicateStrings
    mkDiagnostic
    mkResult
    ;

  inherit (lib)
    attrValues
    filterAttrs
    mapAttrsToList
    optional
    removeSuffix
    subtractLists
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

  matches = regex: value: builtins.match regex value != null;

  # NixOS adds the official cache to every host.
  official = "https://cache.nixos.org";

  normalizeUrl = removeSuffix "/";
in

rec {

  inherit
    mkDiagnostic
    mkResult
    ;

  experimentalFeatures =
    model:
    mkResult (
      map (
        feature:
        diagnostic "nix.experimentalFeatures.missing" [ "experimentalFeatures" ] feature
          "Experimental feature '${feature}' is required: this repository cannot be evaluated without it."
      ) (subtractLists model.experimentalFeatures nix.requiredFeatures)
    );

  caches =
    model:
    let
      urls = map (cache: normalizeUrl cache.url) (attrValues model.caches);
    in
    mkResult (
      mapAttrsToList (
        name: cache:
        diagnostic "nix.cache.url.format" [
          "caches"
          name
          "url"
        ] name "Cache '${name}' URL '${cache.url}' is not https://."
      ) (filterAttrs (_: cache: !matches "https://[^ ]+" cache.url) model.caches)

      ++ mapAttrsToList (
        name: _:
        diagnostic "nix.cache.key.format" [
          "caches"
          name
          "key"
        ] name "Cache '${name}' key is not <name>:<base64>."
      ) (filterAttrs (_: cache: !matches "[^: ]+:[A-Za-z0-9+/]+={0,2}" cache.key) model.caches)

      ++ map (
        url:
        diagnostic "nix.cache.url.duplicate" [ "caches" ] url
          "Cache URL '${url}' is listed more than once${
            lib.optionalString (url == official) " (NixOS already adds the official cache)"
          }."
      ) (duplicateStrings (urls ++ [ official ]))
    );

  package =
    model:
    mkResult (
      optional (!model.package.known) (
        diagnostic "nix.package.unknown" [
          "package"
        ] model.package.path "Nix package '${model.package.path}' is not in pkgs."
      )
    );

  gc =
    model:
    mkResult (
      optional (model.gc.enable && !matches "[0-9]+[dhw]" model.gc.olderThan) (
        diagnostic "nix.gc.olderThan.format" [
          "gc"
          "olderThan"
        ] model.gc.olderThan "gc.olderThan '${model.gc.olderThan}' is not <n>d, <n>h or <n>w."
      )
    );

  all =
    model:
    combine [
      (experimentalFeatures model)
      (caches model)
      (package model)
      (gc model)
    ];

}
