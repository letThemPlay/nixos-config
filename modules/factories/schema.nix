{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.flake = {

    factory = mkOption {
      type = types.attrsOf types.unspecified;
      default = { };
    };

    #
    # The composition root: what a datasheet's `bundles` list picks
    # from. Every feature is present on every host
    # (flake.modules.nixos.features); a bundle only holds settings.
    # Bundles merge, so any file may add to one.
    #
    bundles = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            description = mkOption {
              type = types.str;
              description = "What the bundle turns on, for the README and error messages.";
            };

            module = mkOption {
              type = types.deferredModule;
              default = { };
              description = "Settings the bundle applies to a host.";
            };
          };
        }
      );
      default = { };
      description = "Host bundles by name.";
    };

  };
}
