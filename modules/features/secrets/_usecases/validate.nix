{ lib, diagnostics }:
let
  inherit (diagnostics)
    combine
    mkDiagnostic
    mkResult
    ;

  inherit (lib)
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
    code: predicate: message: model:
    mapAttrsToList (name: file: diagnostic code [ "files" name ] name (message name file)) (
      filterAttrs (_: predicate) model.files
    );

  files =
    model:
    mkResult (
      each "secrets.file.missing" (file: !file.exists) (
        name: _: "Secret '${name}' has no secrets/${name}.age in the repository."
      ) model

      ++ each "secrets.rule.missing" (file: !file.hasRule) (
        name: _: "Secret '${name}' has no \"${name}.age\" entry in secrets/secrets.nix."
      ) model

      # Without a host key the next check cannot run; host.unknown says so.
      ++ lib.optionals (model.host.key != null) (
        each "secrets.recipient.missing" (file: file.hasRule && !file.forHost) (
          name: _:
          "Secret '${name}' is not encrypted for host '${model.host.name}': add keys.hosts.${model.host.name} to \"${name}.age\" in secrets/secrets.nix and run agenix -r."
        ) model
      )
    );

  # Only hosts that use secrets need a key or a decryption identity.
  host =
    model:
    mkResult (
      lib.optionals (model.files != { }) (
        optional (model.host.key == null) (
          diagnostic "secrets.host.unknown" [ "host" ] model.host.name
            "Host '${model.host.name}' uses secrets but has no public key in secrets/keys.nix (hosts.${model.host.name})."
        )

        ++ optional (model.identity.sshHostKey && !model.identity.provided) (
          diagnostic "secrets.identity.missing" [ "identityPaths" ] model.host.name
            "Secrets are decrypted with the SSH host key, but services.openssh is off, so nothing creates it. Enable openssh, or provision the key and set ltp.secrets.hostKeyProvisioned = true."
        )
      )
    );

  all =
    model:
    combine [
      (files model)
      (host model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    files
    host
    all
    ;
}
