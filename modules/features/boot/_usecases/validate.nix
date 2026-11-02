{
  lib,
  boot,
  diagnostics,
}:
let
  inherit (diagnostics)
    combine
    mkDiagnostic
    mkResult
    ;

  inherit (lib) concatStringsSep optional;

  supportedText = concatStringsSep ", " (builtins.attrNames boot.loaders);

  loader =
    model:

    mkResult (
      optional (!model.loader.known) (mkDiagnostic {
        severity = "error";
        code = "boot.loader.unknown";
        target = model.loader.name;
        path = [ "loader" ];
        message = "Unknown boot loader '${model.loader.name}' (known: ${supportedText}).";
      })
    );

  secureBoot =
    model:

    mkResult (
      optional (model.secureBoot.enable && model.loader.known && !model.loader.secureBoot) (mkDiagnostic {
        severity = "error";
        code = "boot.secureBoot.loader.unsupported";
        target = model.loader.name;
        path = [
          "secureBoot"
          "enable"
        ];
        message = "Secure Boot is enabled but loader '${model.loader.name}' cannot sign boot files; unset loader or choose one that can.";
      })
    );

  #
  # TPM2 unlock needs a LUKS root to unlock; storage publishes it.
  #
  tpmUnlock =
    model:

    mkResult (
      optional (model.tpmUnlock.enable && model.tpmUnlock.luksName == null) (mkDiagnostic {
        severity = "error";
        code = "boot.tpmUnlock.encryption.missing";
        target = "tpmUnlock";
        path = [
          "tpmUnlock"
          "enable"
        ];
        message = "TPM unlock is enabled but the root is not encrypted; enable ltp.storage.encryption.";
      })
    );

  all =
    model:

    combine [
      (loader model)
      (secureBoot model)
      (tpmUnlock model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    loader
    secureBoot
    tpmUnlock
    all
    ;
}
