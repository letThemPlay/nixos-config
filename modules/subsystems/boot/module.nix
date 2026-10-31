{ config, inputs, ... }:
let
  boot = config.flake.subsystems.boot;
in
{
  flake.nixosModules.boot =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        mapAttrsToList
        mkIf
        mkMerge
        ;

      cfg = config.ltp.boot;

      #
      # The storage facts read only storage's own options, never
      # persistence, so they are safe here even though this module
      # declares persistence.state.
      #
      model = boot.normalize {
        inherit cfg;
        storage = config.ltp.storage.facts;
      };

      validation = boot.validate.all model;

      packagesOf = map (name: pkgs.${name});

      #
      # How each loader's settings reach NixOS. Every key of
      # boot.loaders needs an entry here.
      #
      loaderOptions = {
        systemd-boot = settings: {
          boot.loader.systemd-boot = {
            enable = true;
          }
          // settings;
        };

        lanzaboote = settings: {
          boot.lanzaboote = {
            enable = true;
          }
          // settings;
        };
      };

      #
      # Every registered loader renders behind mkIf (model.loader.name
      # == name), so the module's shape does not depend on config.
      #
      renderLoader =
        name: loader:
        let
          rendered = loader.render { inherit model; };
        in
        mkIf (model.loader.name == name) (mkMerge [
          (loaderOptions.${name} rendered.settings)

          {
            boot.loader.efi.canTouchEfiVariables = rendered.canTouchEfiVariables;

            environment.systemPackages = packagesOf rendered.packages;

            ltp.storage.persistence.state = mkIf config.ltp.storage.enable rendered.state;
          }
        ]);

      tpm = boot.tpm { inherit model; };

      format = diagnostic: "ltp.boot [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      config = mkIf cfg.enable (mkMerge [

        {
          assertions = errors;

          warnings = map format validation.warnings;

          # Needed for TPM2 unlock and the storage rollback.
          boot.initrd.systemd.enable = true;
        }

        #
        # Rendering only runs on a valid model; invalid models stop at
        # the assertions above with a readable diagnostic.
        #
        (mkIf validation.ok (
          mkMerge (
            [
              {
                boot.initrd.luks.devices = tpm.devices;

                environment.systemPackages = packagesOf tpm.packages;
              }
            ]

            ++ mapAttrsToList renderLoader boot.loaders
          )
        ))

      ]);
    };
}
