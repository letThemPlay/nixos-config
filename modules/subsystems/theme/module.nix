{ config, ... }:
let
  theme = config.flake.subsystems.theme;
in
{
  flake.nixosModules.theme =
    { config, lib, ... }:

    let
      inherit (lib) mkIf mkMerge;

      cfg = config.ltp.theme;

      model = theme.normalize {
        inherit cfg;
        users = config.ltp.identity.facts.users;
      };

      validation = theme.validate.all model;

      format = diagnostic: "ltp.theme [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      config = mkMerge [

        # Published on every host, like the other subsystems' facts.
        { ltp.theme.facts.users = model.users; }

        (mkIf cfg.enable {
          assertions = errors;

          warnings = map format validation.warnings;
        })

      ];
    };
}
