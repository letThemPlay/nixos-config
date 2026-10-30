_: {
  flake.library.storageValidate =
    {
      config,
      lib,
      ...
    }:

    let
      inherit (config.flake.library.storage)
        types
        ;

      inherit (lib)
        concatLists
        filter
        flatten
        groupBy
        map
        mapAttrsToList
        subtractLists
        unique
        ;

      duplicateStrings =
        values:

        assert builtins.all builtins.isString values;

        let
          grouped = groupBy (x: x) values;
        in
        flatten (
          mapAttrsToList (value: members: if builtins.length members > 1 then [ value ] else [ ]) grouped
        );

      mkDiagnostic =
        {
          severity,
          code,
          target,
          path ? [ ],
          message,
        }:
        {
          inherit
            severity
            code
            target
            path
            message
            ;
        };

      mkResult =
        diagnostics:

        let
          errors = filter (d: d.severity == "error") diagnostics;

          warnings = filter (d: d.severity == "warning") diagnostics;
        in
        {
          ok = errors == [ ];

          inherit
            diagnostics
            errors
            warnings
            ;

          errorCount = builtins.length errors;
          warningCount = builtins.length warnings;
        };

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

      backend =
        model:

        let
          supported = [
            "btrfs"
          ];
        in

        mkResult (
          if builtins.elem model.backend supported then
            [ ]
          else
            [
              (mkDiagnostic {
                severity = "error";
                code = "storage.backend.unsupported";
                target = model.backend;
                path = [ "backend" ];
                message = "Unsupported backend '${model.backend}'.";
              })
            ]
        );

      persistence =
        model:

        let
          persistenceVolumeIds = builtins.attrNames model.persistence;

          volumeIds = builtins.attrNames model.volumes;

          unknownPersistenceVolumes = subtractLists persistenceVolumeIds volumeIds;

          unmountedPersistenceVolumes = filter (
            volume: volume.mountpoint == null && builtins.hasAttr volume.id model.persistence
          ) (builtins.attrValues model.volumes);
        in

        mkResult (
          (map (
            volumeId:
            mkDiagnostic {
              severity = "error";
              code = "storage.persistence.volume.unknown";
              target = volumeId;
              path = [
                "persistence"
                volumeId
              ];
              message = "Persistence policy references unknown volume '${volumeId}'.";
            }
          ) unknownPersistenceVolumes)

          ++

            (map (
              volume:
              mkDiagnostic {
                severity = "error";
                code = "storage.persistence.volume.unmounted";
                target = volume.id;
                path = [
                  "persistence"
                  volume.id
                ];
                message = "Persistence policy references volume '${volume.id}', which has no mountpoint.";
              }
            ) unmountedPersistenceVolumes)
        );

      all =
        model:

        let
          validations = [
            (requiredRoles model)
            (uniqueRoles model)
            (uniqueMountpoints model)
            (backend model)
            (persistence model)
          ];
        in

        mkResult (concatLists (map (v: v.diagnostics) validations));

    };

}
