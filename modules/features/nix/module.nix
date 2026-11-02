{ config, ... }:
let
  nix = config.ltp.features.nix;
in
{
  flake.nixosModules.nix =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:

    let
      inherit (lib) mkIf mkMerge;

      cfg = config.ltp.nix;

      packagePath = lib.splitString ".";

      model = nix.normalize {
        inherit cfg;
        hasPackage = path: lib.hasAttrByPath (packagePath path) pkgs;
      };

      validation = nix.validate.all model;

      rendered = nix.settings { inherit model; };

      inherit (config.networking) hostName;

      format = diagnostic: "ltp.nix [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      config = mkIf cfg.enable (mkMerge [

        {
          assertions = errors;

          warnings = map format validation.warnings;
        }

        #
        # Rendering only runs on a valid model; invalid models stop at
        # the assertions above with a readable diagnostic.
        #
        (mkIf validation.ok {
          nix = {
            package = lib.getAttrFromPath (packagePath model.package.path) pkgs;

            inherit (rendered) settings;

            gc = mkIf rendered.gc.automatic rendered.gc;
          };

          # The CLI for the cachix caches.
          environment.systemPackages = [ pkgs.cachix ];
        })

        #
        # Rebuild this host from the flake in the current directory.
        # Only where the shell feature is present (not on the ISO).
        #
        (lib.optionalAttrs (options ? ltp.shell) {
          ltp.shell.aliases = {
            nrs = "sudo nixos-rebuild switch --flake .#${hostName}";
            nrb = "sudo nixos-rebuild boot --flake .#${hostName}";
            nfc = "nix flake check";
          };
        })

      ]);
    };
}
