{ lib, ... }: {
  options.ltp.hosts.registry = lib.mkOption {
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
        };
      }
    );
  };

  options.ltp.stylixOverrides = lib.mkOption {
    description = "Strict typing container box for host-dependent visual scales and metrics.";
    default = { };
    type = lib.types.submodule {
      options = {
        cursorSize = lib.mkOption {
          type = lib.types.int;
          default = 24;
        };
        fontSize = lib.mkOption {
          default = { };
          type = lib.types.submodule {
            options = {
              terminal = lib.mkOption {
                type = lib.types.int;
                default = 11;
              };
              applications = lib.mkOption {
                type = lib.types.int;
                default = 12;
              };
              desktop = lib.mkOption {
                type = lib.types.int;
                default = 10;
              };
            };
          };
        };
      };
    };
  };
}
