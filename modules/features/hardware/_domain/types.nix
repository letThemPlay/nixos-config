{ lib }:
let
  inherit (lib) mkOption types;
in
rec {

  vendor = types.enum [
    "amd"
    "intel"
    "nvidia"
  ];

  prime = types.enum [
    "offload"
    "sync"
    "none"
  ];

  gpu = types.submodule {
    options = {

      vendor = mkOption {
        type = vendor;
      };

      integrated = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this is the integrated GPU of a PRIME pair.";
      };

      busId = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "PCI:1:0:0";
        description = ''
          PCI address as PCI:<bus>:<device>:<function> in decimal. lspci
          prints hex: 01:00.0 is PCI:1:0:0.
        '';
      };

    };
  };

  model = types.submodule {
    options = {

      gpus = mkOption {
        type = types.attrsOf gpu;
      };

      prime = mkOption {
        type = types.submodule {
          options = {
            mode = mkOption { type = prime; };

            active = mkOption {
              type = types.bool;
              description = "Whether an nvidia GPU and an integrated GPU form a PRIME pair.";
            };
          };
        };
      };

      audio = mkOption {
        type = types.bool;
      };

      bluetooth = mkOption {
        type = types.bool;
      };

      guest = mkOption {
        type = types.submodule {
          options = {
            name = mkOption { type = types.nullOr types.str; };
            known = mkOption { type = types.bool; };
          };
        };
      };

    };
  };

}
