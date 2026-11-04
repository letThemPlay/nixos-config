{ config, ... }:
let
  theme = config.ltp.features.theme;
in
{
  flake.nixosModules.theme =
    {
      config,
      lib,
      pkgs,
      ...
    }:

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

        # Published on every host, like the other features' facts.
        {
          ltp.theme.facts = {
            inherit (model) users ui;
          };
        }

        (mkIf cfg.enable {
          assertions = errors;

          warnings = map format validation.warnings;

          # The monospace font and the extra ones, for every program.
          fonts.packages = map (path: lib.getAttrFromPath (lib.splitString "." path) pkgs) (
            [ cfg.appearance.fonts.monospace.package ] ++ cfg.appearance.fonts.extra
          );
        })

      ];
    };
}
