_: {
  # Options only.
  flake.nixosModules.bundles-options =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.bundles = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the selected bundles apply their settings.";
        };

        selected = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "base"
            "laptop"
          ];
          description = ''
            Bundles from the catalogue, set by the host factory from the
            host's bundles list. The bundles they require apply too.
          '';
        };

        facts = {

          known = mkOption {
            type = types.listOf types.str;
            readOnly = true;
            description = "Every bundle name in the catalogue.";
          };

          active = mkOption {
            type = types.listOf types.str;
            readOnly = true;
            description = "The selected bundles and every bundle they require.";
          };

        };

      };
    };
}
