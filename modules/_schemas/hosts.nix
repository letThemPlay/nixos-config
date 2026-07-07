{ lib, ... }: {
  options.registry.hosts = lib.mkOption {
    description = "The central structural metadata model tracker for all machine host configurations.";
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          hostName = lib.mkOption { type = lib.types.str; };
          architecture = lib.mkOption {
            type = lib.types.str;
            default = "x86_64-linux";
          };
          stateVersion = lib.mkOption {
            type = lib.types.str;
            default = "26.05";
          };
          isLaptop = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          features = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          users = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          extraModules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [ ];
          };
          featureConfig = lib.mkOption {
            type = lib.types.attrsOf lib.types.unspecified;
            default = { };
          };
        };
      }
    );
  };
}
