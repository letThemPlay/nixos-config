{
  lib,
  storage,
  diagnostics,
}:
let
  inherit (storage) query;

  inherit (diagnostics)
    combine
    duplicateStrings
    mkDiagnostic
    mkResult
    ;

  supportedLayoutVersions = [ 1 ];

  inherit (lib)
    concatLists
    filter
    map
    hasPrefix
    mapAttrsToList
    optional
    subtractLists
    ;

in

rec {

  inherit
    mkDiagnostic
    mkResult
    ;

  requiredRoles =
    model:

    let
      actual = map (v: v.role) (builtins.attrValues model.volumes);

      missing = subtractLists actual model.layout.requiredRoles;
    in

    mkResult (
      map (
        role:
        mkDiagnostic {
          severity = "error";
          code = "storage.role.missing";
          target = role;
          path = [
            "layout"
            "requiredRoles"
          ];
          message = "Required role '${role}' is missing.";
        }
      ) missing
    );

  uniqueRoles =
    model:

    let
      duplicates = duplicateStrings (map (v: v.role) (builtins.attrValues model.volumes));
    in

    mkResult (
      map (
        role:
        mkDiagnostic {
          severity = "error";
          code = "storage.role.duplicate";
          target = role;
          message = "Role '${role}' is defined more than once.";
        }
      ) duplicates
    );

  uniqueMountpoints =
    model:

    let
      duplicates = duplicateStrings (
        map (v: v.mountpoint) (filter (v: v.mountpoint != null) (builtins.attrValues model.volumes))
      );
    in

    mkResult (
      map (
        mount:
        mkDiagnostic {
          severity = "error";
          code = "storage.mountpoint.duplicate";
          target = mount;
          message = "Mountpoint '${mount}' is defined more than once.";
        }
      ) duplicates
    );

  #
  # The model backend and every per-volume backend override must be
  # registered; renderers skip volumes of other backends.
  #
  backend =
    model:

    let
      supported = builtins.attrNames storage.backends;

      supportedText = lib.concatStringsSep ", " supported;

      # Volumes that inherit the model backend are covered above.
      unknownVolumes = filter (
        volume: volume.backend != model.backend && !builtins.elem volume.backend supported
      ) (query.all model);
    in

    mkResult (
      optional (!builtins.elem model.backend supported) (mkDiagnostic {
        severity = "error";
        code = "storage.backend.unknown";
        target = model.backend;
        path = [ "backend" ];
        message = "Unknown backend '${model.backend}' (known: ${supportedText}).";
      })

      ++ map (
        volume:
        mkDiagnostic {
          severity = "error";
          code = "storage.volume.backend.unknown";
          target = volume.id;
          path = [
            "volumes"
            volume.id
            "backend"
          ];
          message = "Volume '${volume.id}' uses unknown backend '${volume.backend}' (known: ${supportedText}).";
        }
      ) unknownVolumes
    );

  layout =
    model:

    mkResult (
      optional (!model.layout.known) (mkDiagnostic {
        severity = "error";
        code = "storage.layout.unknown";
        target = model.layout.name;
        path = [ "layout" ];
        message = "Unknown storage layout '${model.layout.name}'.";
      })

      #
      # Layouts declare the schema version they were written for;
      # bump the supported list when the layout schema changes.
      #
      ++
        optional (model.layout.known && !builtins.elem model.layout.version supportedLayoutVersions)
          (mkDiagnostic {
            severity = "error";
            code = "storage.layout.version.unsupported";
            target = model.layout.name;
            path = [
              "layout"
              "version"
            ];
            message = "Layout '${model.layout.name}' has schema version ${toString model.layout.version}; supported: ${
              lib.concatMapStringsSep ", " toString supportedLayoutVersions
            }.";
          })
    );

  #
  # Each persistence target must be a mounted, boot-critical volume
  # that survives reboots.
  #
  persistence =
    model:

    let
      check =
        volumeId: _:

        let
          volume = model.volumes.${volumeId} or null;

          diagnostic =
            code: message:
            mkDiagnostic {
              severity = "error";
              inherit code message;
              target = volumeId;
              path = [
                "persistence"
                volumeId
              ];
            };
        in

        if volume == null then
          [
            (diagnostic "storage.persistence.volume.unknown" "Persistence policy references unknown volume '${volumeId}'.")
          ]
        else
          optional (volume.mountpoint == null) (
            diagnostic "storage.persistence.volume.unmounted" "Persistence policy references volume '${volumeId}', which has no mountpoint."
          )

          ++ optional volume.rollback (
            diagnostic "storage.persistence.volume.rollback" "Persistence policy references volume '${volumeId}', which is erased on every boot."
          )

          ++ optional (volume.mountpoint != null && !volume.neededForBoot) (
            diagnostic "storage.persistence.volume.lateMount" "Persistence policy references volume '${volumeId}', which is not neededForBoot."
          );
    in

    mkResult (concatLists (mapAttrsToList check model.persistence));

  #
  # Rollback recreates volumes from a template snapshot.
  #
  rollback =
    model:

    let
      rollbackVolumes = query.rollback model;

      templates = query.byCategory model "template";
    in

    mkResult (
      optional (rollbackVolumes != [ ] && templates == [ ]) (mkDiagnostic {
        severity = "error";
        code = "storage.rollback.template.missing";
        target = model.layout.name;
        path = [ "volumes" ];
        message = "Volumes marked for rollback require a volume with category 'template'.";
      })

      ++ optional (builtins.length templates > 1) (mkDiagnostic {
        severity = "error";
        code = "storage.rollback.template.ambiguous";
        target = model.layout.name;
        path = [ "volumes" ];
        message = "Only one volume with category 'template' may be defined.";
      })
    );

  disk =
    model:

    let
      device = model.platform.disk;
    in

    mkResult (
      optional (!hasPrefix "/dev/disk/by-" device) (mkDiagnostic {
        severity = "warning";
        code = "storage.disk.unstable";
        target = device;
        path = [
          "platform"
          "disk"
        ];
        message = "Disk '${device}' is not a stable /dev/disk/by-* path.";
      })
    );

  #
  # Feature-declared state needs a volume with the layout's stateRole.
  #
  state =
    model:

    mkResult (
      optional (model.unassignedState != null) (mkDiagnostic {
        severity = "error";
        code = "storage.persistence.state.unassigned";
        target = model.layout.stateRole;
        path = [
          "persistence"
          "state"
        ];
        message = "persistence.state has entries but no volume has role '${model.layout.stateRole}'.";
      })
    );

  all =
    model:

    let
      validations = [
        (layout model)
        (requiredRoles model)
        (uniqueRoles model)
        (uniqueMountpoints model)
        (backend model)
        (persistence model)
        (rollback model)
        (disk model)
        (state model)
      ];
    in

    combine validations;

}
