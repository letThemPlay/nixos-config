{ config, ... }:
let
  locale = config.flake.features.locale;
in
{
  flake.nixosModules.locale =
    { config, lib, ... }:

    let
      inherit (lib) mkIf mkMerge;

      cfg = config.ltp.locale;

      model = locale.normalize cfg;

      validation = locale.validate.all model;

      settings = locale.nixos { inherit model; };

      format = diagnostic: "ltp.locale [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      config = mkIf cfg.enable (mkMerge [

        {
          assertions = errors;

          warnings = map format validation.warnings;
        }

        #
        # Rendering only runs on a valid model; invalid models stop at
        # the assertions above with a readable diagnostic.
        #
        (mkIf validation.ok {
          inherit (settings) time i18n console;

          services.xserver.xkb = settings.xkb;
        })

      ]);
    };
}
