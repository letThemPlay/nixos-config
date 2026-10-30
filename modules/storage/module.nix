{ config, inputs, ... }:
let
  storage = config.flake.factory.storage;
in
{
  flake.nixosModules.storage =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:

    let
      inherit (lib)
        filter
        listToAttrs
        mkIf
        mkMerge
        nameValuePair
        ;

      cfg = config.ohmydarlings.storage;

      model = storage.normalize cfg;

      validation = storage.validate.all model;

      #
      # Selected statically: choosing by model.backend would make the
      # shape of this module depend on config. Validation rejects other
      # backends; additional ones need their own mkIf-guarded block.
      #
      transform = storage.transform.btrfs;

      disko = transform.disko { inherit model; };

      rollback = transform.rollback {
        inherit model pkgs utils;
        inherit (disko) rootDevice;
      };

      preservation = transform.preservation { inherit model; };

      persist = storage.query.stateVolume model;

      ephemeralRoot = storage.query.ephemeralRoot model;

      format = diagnostic: "ohmydarlings.storage [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.preservation.nixosModules.default
      ];

      config = mkMerge [

        #
        # The read-only facts get exactly one definition on every host.
        # They read only volumes and never sit behind the validation.ok
        # guard: validation reads persistence.state, which features may
        # define conditionally on these facts.
        #
        {
          ohmydarlings.storage.facts = {
            ephemeralRoot = cfg.enable && ephemeralRoot;

            statePath = if cfg.enable && persist != null then persist.mountpoint else null;
          };
        }

        (mkIf cfg.enable (mkMerge [

          {
            #
            # A host that still defines its own fileSystems."/" (e.g. from
            # nixos-generate-config) fails with the module system's
            # conflicting-definition error, which names both files.
            #
            assertions = errors;

            warnings = map format validation.warnings;
          }

          #
          # Rendering only runs on a valid model; invalid models stop at
          # the assertions above with a readable diagnostic.
          #
          (mkIf validation.ok (mkMerge [

            {
              disko.devices = disko.devices;

              #
              # disko does not set neededForBoot; preservation and the
              # rollback need these volumes mounted in initrd.
              #
              fileSystems = listToAttrs (
                map (volume: nameValuePair volume.mountpoint { neededForBoot = true; }) (
                  filter (volume: volume.mountpoint != null) (storage.query.neededForBoot model)
                )
              );

              boot.initrd.systemd = mkMerge [
                rollback
                { enable = true; }
              ];
            }

            preservation

          ]))

        ]))

      ];
    };
}
