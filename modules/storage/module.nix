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
        any
        filter
        filterAttrs
        listToAttrs
        mapAttrs
        mkDefault
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

      persist = storage.query.byRole model "persist";

      ephemeralRoot = any (volume: volume.mountpoint == "/") (storage.query.rollback model);

      passwordDirectory =
        if cfg.passwordDirectory != null then
          cfg.passwordDirectory
        else
          "${persist.mountpoint}/secrets/passwords";

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

      config = mkIf cfg.enable (mkMerge [

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

          #
          # With an ephemeral /etc, password changes made at runtime are
          # lost. Users are declarative and read their hash from the
          # persist volume; mutableUsers = false also enables the NixOS
          # assertion that a wheel user or root has a password.
          #
          (mkIf (ephemeralRoot && persist != null) {
            users.mutableUsers = false;

            users.users = mapAttrs (username: _: {
              hashedPasswordFile = mkDefault "${passwordDirectory}/${username}";
            }) (filterAttrs (_: profile: profile.enable) config.users.profiles);
          })

        ]))

      ]);
    };
}
