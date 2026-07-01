{ lib, ... }: {
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
