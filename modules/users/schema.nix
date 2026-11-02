{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  #
  # The user catalogue: one flake-parts module per user under
  # modules/users/<name>/. Users merge, so any file may add to one.
  #
  options.flake.users = mkOption {
    type = types.attrsOf (
      types.submodule {
        # Identity fields; ltp.identity checks them with its user type.
        freeformType = types.lazyAttrsOf types.anything;

        options.home = mkOption {
          type = types.deferredModule;
          default = { };
          description = "home-manager settings for this user, on hosts that enable them.";
        };
      }
    );
    default = { };
    description = "Users by account name.";
  };
}
