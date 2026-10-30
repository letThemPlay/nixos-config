{ config, lib, ... }:
{
  flake.library.storageTransformBtrfsPreservation =
    let
      inherit (lib)
        any
        concatMap
        filterAttrs
        isString
        mapAttrs'
        mkIf
        nameValuePair
        optionalAttrs
        zipAttrsWith
        ;

      query = config.flake.library.storageQuery;

      #
      # Unset typed settings are null; preservation applies its own
      # defaults when a key is absent.
      #
      clean = entry: if isString entry then entry else filterAttrs (_: value: value != null) entry;

      mergePolicies = zipAttrsWith (
        _: policies: {
          directories = concatMap (policy: policy.directories or [ ]) policies;
          files = concatMap (policy: policy.files or [ ]) policies;
        }
      );

      userbornState = "/var/lib/userborn";
    in

    #
    # Produces NixOS configuration for nix-community/preservation.
    #
    { model }:

    let
      persist = query.byRole model "persist";

      #
      # With an ephemeral root, /etc is recreated on every boot, so the
      # machine identity and user database must be preserved explicitly.
      #
      ephemeralRoot = any (volume: volume.mountpoint == "/") (query.rollback model);

      essentials = ephemeralRoot && persist != null;

      essentialPolicy = optionalAttrs essentials {
        ${persist.id} = {
          directories = [
            {
              directory = userbornState;
              inInitrd = true;
            }
          ];

          files = [
            {
              file = "/etc/machine-id";
              how = "symlink";
              inInitrd = true;
              configureParent = true;
            }
          ];
        };
      };

      policies = mergePolicies [
        model.persistence
        essentialPolicy
      ];

      preserveAt = mapAttrs' (
        volumeId: policy:

        let
          volume = model.volumes.${volumeId};
        in
        nameValuePair volume.mountpoint {
          directories = map clean policy.directories;

          files = map clean policy.files;
        }
      ) policies;

    in

    #
    # Keys are fixed and conditions sit inside mkIf: the module system
    # must know the attribute names before the model can be evaluated.
    #
    {
      preservation = {
        enable = preserveAt != { };

        inherit preserveAt;
      };

      #
      # userborn keeps passwd, group and shadow in its preserved state
      # directory and links them into /etc.
      #
      services.userborn = mkIf essentials {
        enable = true;

        passwordFilesLocation = userbornState;
      };

      #
      # First boot: seed the persistent machine-id as "uninitialized" so
      # ConditionFirstBoot holds, then commit the generated ID to the
      # persistent volume instead of /etc.
      #
      boot.initrd.systemd.tmpfiles.settings.preservation = mkIf essentials {
        "/sysroot${persist.mountpoint}/etc/machine-id".f = {
          argument = "uninitialized";
        };
      };

      systemd.services.systemd-machine-id-commit = mkIf essentials {
        unitConfig.ConditionPathIsMountPoint = [
          ""
          "${persist.mountpoint}/etc/machine-id"
        ];

        serviceConfig.ExecStart = [
          ""
          "systemd-machine-id-setup --commit --root ${persist.mountpoint}"
        ];
      };
    };
}
