{ config, lib, ... }:
{
  flake.library.storageNormalize =
    let
      inherit (lib)
        attrValues
        concatMap
        filter
        mapAttrs
        optionalAttrs
        zipAttrsWith
        ;

      inherit (config.flake.library)
        storageLayouts
        ;

      mergePolicies = zipAttrsWith (
        _: policies: {
          directories = concatMap (policy: policy.directories) policies;
          files = concatMap (policy: policy.files) policies;
        }
      );
    in

    #
    # cfg is the evaluated ohmydarlings.storage option set.
    #
    # Layout volumes have already been merged into cfg.volumes by the
    # module system, so normalization only resolves inheritance and
    # gathers platform settings.
    #
    cfg:

    let
      known = builtins.hasAttr cfg.layout storageLayouts;

      layout =
        storageLayouts.${cfg.layout} or {
          version = 1;
          description = "";
          requiredRoles = [ ];
        };

      stateRole = layout.stateRole or "persist";

      backend = cfg.filesystem.type;

      normalizedVolumes = mapAttrs (
        id: volume:
        volume
        // {
          inherit id;

          backend = if volume.backend == null then backend else volume.backend;
        }
      ) cfg.volumes;

      #
      # Feature-declared state goes to the volume with the layout's
      # stateRole; without one it is kept aside for validation.
      #
      stateVolumes = filter (volume: volume.role == stateRole) (attrValues normalizedVolumes);

      inherit (cfg.persistence) state;

      hasState = state.directories != [ ] || state.files != [ ];

      stateTarget = if stateVolumes == [ ] then null else (builtins.head stateVolumes).id;

    in
    {
      version = 1;

      layout = {
        name = cfg.layout;

        inherit known stateRole;

        version = layout.version or 1;

        inherit (layout)
          description
          requiredRoles
          ;
      };

      inherit (cfg) renderer;

      inherit backend;

      volumes = normalizedVolumes;

      persistence = mergePolicies [
        cfg.persistence.policy
        (optionalAttrs (hasState && stateTarget != null) { ${stateTarget} = state; })
      ];

      unassignedState = if hasState && stateTarget == null then state else null;

      inherit (cfg) rollback;

      platform = {
        inherit (cfg)
          disk
          boot
          swap
          encryption
          filesystem
          ;
      };
    };
}
