_: {
  flake.nixosModules.user-schema = { lib, ... }: {
    options.ltp.users.registry = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            username = lib.mkOption { type = lib.types.str; };
            fullName = lib.mkOption { type = lib.types.str; };
            email = lib.mkOption { type = lib.types.str; };
            features = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
      default = { };
      description = "The central, unified registry for all user personas across the flake.";
    };
  };
}
