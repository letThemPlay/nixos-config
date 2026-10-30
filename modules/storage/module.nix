{ config, ... }:
let
  storage = config.flake.factory.storage;
in
{
  flake.nixosModules.storage =
    {
      config,
      lib,
      ...
    }:

    let
      cfg = config.ohmydarlings.storage;

      model = storage.normalize cfg;

      validation = storage.validate.all model;

      #      preservation = storage.transform.btrfs.preservation {
      #        inherit model;
      #      };

      errors = map (diagnostic: {
        assertion = false;
        message = "ohmydarlings.storage [${diagnostic.code}]: ${diagnostic.message}";
      }) validation.errors;

      warnings = map (
        diagnostic: "ohmydarlings.storage [${diagnostic.code}]: ${diagnostic.message}"
      ) validation.warnings;
    in
    {
      config = lib.mkIf cfg.enable {

        assertions = errors;

        inherit warnings;

        #        preservation = preservation;
      };
    };
}
