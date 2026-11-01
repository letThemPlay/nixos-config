{ config, ... }:
let
  nix = config.flake.subsystems.nix;
in
{
  # Options only.
  flake.nixosModules.nix-api =
    { lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.ltp.nix = {

        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the nix subsystem configures Nix itself.";
        };

        package = mkOption {
          type = types.str;
          default = "nixVersions.latest";
          description = "Nix package, as a pkgs attribute path.";
        };

        experimentalFeatures = mkOption {
          type = types.listOf types.str;
          default = nix.requiredFeatures;
          description = ''
            Enabled experimental features. nix-command, flakes and
            pipe-operators are required by this repository.
          '';
        };

        optimiseStore = mkOption {
          type = types.bool;
          default = true;
          description = "Whether identical store files are hard-linked (auto-optimise-store).";
        };

        defaultCaches = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the default caches (nix-community) are used.";
        };

        caches = mkOption {
          type = types.attrsOf nix.types.cache;
          default = { };
          description = ''
            Additional binary caches by name. The official
            https://cache.nixos.org/ is always added by NixOS.
          '';
        };

        gc = mkOption {
          type = nix.types.gc;
          default = { };
          description = "Periodic garbage collection.";
        };

      };
    };
}
