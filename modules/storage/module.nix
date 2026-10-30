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
        message = diagnostic.message;
      }) validation.errors;
    in
    {
      config = lib.mkIf cfg.enable {

        assertions = errors;

        #        preservation = preservation;
      };
    };
}
