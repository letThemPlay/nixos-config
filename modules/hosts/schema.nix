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
                description = "Bundles from the bundles catalogue (modules/features/bundles), with the ones they require.";
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

  };
}
