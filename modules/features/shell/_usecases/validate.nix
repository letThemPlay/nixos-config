{
  lib,
  shell,
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
    ;
in

rec {

  inherit
    mkDiagnostic
    mkResult
    ;

  users =
    model:
    mkResult (
      mapAttrsToList (
        name: user:
        mkDiagnostic {
          severity = "error";
          code = "shell.user.unknown";
          target = name;
          path = [
            "users"
            name
            "shell"
          ];
          message = "User '${name}' logs in with unknown shell '${user.shell}' (known: ${concatStringsSep ", " (attrNames shell.shells)}).";
        }
      ) (filterAttrs (_: user: !user.known) model.users)
    );

  all = model: combine [ (users model) ];

}
