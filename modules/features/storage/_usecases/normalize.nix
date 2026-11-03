{ lib, storage }:
let
  inherit (lib)
    attrNames
    attrValues
    concatMap
    filter
    genAttrs
    optionalAttrs
    unique
    zipAttrsWith
    ;

  storageLayouts = storage.layouts;
  storageTypes = storage.types;

  # Layout policies are plain data and may omit either list.
  mergePolicies = zipAttrsWith (
    _: policies: {
      directories = concatMap (policy: policy.directories or [ ]) policies;
      files = concatMap (policy: policy.files or [ ]) policies;
    }
  );

in

#
# cfg is the ltp.storage option set, or any attrset of the
# same shape: layout, backend, volumes (partial overrides),
# persistence.{defaultPolicy,policy,state}, rollback and
# the platform settings. No module system is required.
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

  inherit (cfg) backend;

  layoutVolumes = layout.volumes or { };

  #
  # defaults <- layout volume <- host override. An attribute that
  # exists only in the overrides adds a new volume. An unknown
  # layout contributes nothing; validation reports it.
  #
  normalizedVolumes = genAttrs (unique (attrNames layoutVolumes ++ attrNames cfg.volumes)) (
    id:
    let
      volume = storageTypes.applyVolumeOverride (
        storageTypes.volumeDefaults id // (layoutVolumes.${id} or { })
      ) (cfg.volumes.${id} or { });
    in
    volume
    // {
      inherit id;

      backend = if volume.backend == null then backend else volume.backend;
    }
  );

  layoutPolicy = if cfg.persistence.defaultPolicy then layout.persistence or { } else { };

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
  layout = {
    name = cfg.layout;

    inherit known stateRole;

    version = layout.version or 1;

    inherit (layout)
      description
      requiredRoles
      ;
  };

  inherit backend;

  volumes = normalizedVolumes;

  persistence = mergePolicies [
    layoutPolicy
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
      labels
      encryption
      filesystem
      ;
  };
}
