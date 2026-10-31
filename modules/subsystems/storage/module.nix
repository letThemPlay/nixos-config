{ config, inputs, ... }:
let
  storage = config.flake.subsystems.storage;
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
        mapAttrsToList
        mkIf
        mkMerge
        nameValuePair
        ;

      cfg = config.ltp.storage;

      model = storage.normalize cfg;

      validation = storage.validate.all model;

      #
      # Every registered backend renders behind mkIf (model.backend ==
      # name): attribute names stay fixed and the selection is lazy, so
      # the module's shape does not depend on config. Adding a backend
      # only means registering it in storage.backends.
      #
      # Transforms return plain data; conditions stay inside mkIf here.
      #
      renderBackend =
        name: backend:
        let
          disko = backend.disko { inherit model; };

          rollback = backend.rollback {
            inherit model pkgs utils;
            inherit (disko) rootDevice;
          };
        in
        mkIf (model.backend == name) {
          disko.devices = disko.devices;

          boot.initrd.systemd = {
            storePaths = mkIf rollback.active [ rollback.script ];

            services.storage-rollback = mkIf rollback.active rollback.service;
          };
        };

      preservation = storage.preservation { inherit model; };

      persist = storage.query.stateVolume model;

      ephemeralRoot = storage.query.ephemeralRoot model;

      format = diagnostic: "ltp.storage [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.preservation.nixosModules.default

        # Kept here rather than in storage-api: it needs NixOS assertions.
        (lib.mkRemovedOptionModule [
          "ltp"
          "storage"
          "renderer"
        ] "disko is the only renderer; select the filesystem backend with ltp.storage.filesystem.type.")
      ];

      config = mkMerge [

        #
        # The read-only facts get exactly one definition on every host.
        # They read only volumes and never sit behind the validation.ok
        # guard: validation reads persistence.state, which features may
        # define conditionally on these facts.
        #
        {
          ltp.storage.facts = {
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
          (mkIf validation.ok (
            mkMerge (
              [
                {
                  #
                  # disko does not set neededForBoot; preservation and the
                  # rollback need these volumes mounted in initrd.
                  #
                  fileSystems = listToAttrs (
                    map (volume: nameValuePair volume.mountpoint { neededForBoot = true; }) (
                      filter (volume: volume.mountpoint != null) (storage.query.neededForBoot model)
                    )
                  );

                  boot.initrd.systemd.enable = true;

                  preservation = {
                    enable = preservation.preserveAt != { };

                    inherit (preservation) preserveAt;
                  };
                }
              ]

              ++ mapAttrsToList renderBackend storage.backends
            )
          ))

        ]))

      ];
    };
}
