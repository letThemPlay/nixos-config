{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.ltp = {

    factory = mkOption {
      type = types.attrsOf types.unspecified;
      default = { };
    };

    #
    # The fleet: one flake-parts module per host under
    # modules/hosts/<name>/. A host merges, so any file may add to its
    # module.
    #
    hosts = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              system = mkOption {
                type = types.str;
                example = "x86_64-linux";
              };

              hostId = mkOption {
                type = types.strMatching "[0-9a-f]{8}";
                default = builtins.substring 0 8 (builtins.hashString "sha256" name);
                defaultText = lib.literalExpression "first 8 hex digits of sha256(host name)";
                description = "networking.hostId: 8 hex digits, unique per machine.";
              };

              stateVersion = mkOption {
                type = types.str;
                description = "The release the host was installed with; never change it later.";
              };

              bundles = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Bundles (ltp.bundles) applied to the host.";
              };

              users = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Users (ltp.users) enabled on the host.";
              };

              module = mkOption {
                type = types.deferredModule;
                default = { };
                description = "The host's own NixOS settings: hardware profile and ltp.* options.";
              };
            };
          }
        )
      );
      default = { };
      description = "Hosts by host name.";
    };

    #
    # The composition root: what a host's `bundles` list picks
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
