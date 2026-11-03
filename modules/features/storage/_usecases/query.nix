{ lib }:
let
  inherit (lib)
    attrByPath
    attrNames
    attrValues
    hasAttr
    ;

  #
  # Internal helper.
  #
  # Always work with the normalized list representation.
  #
  volumes = model: attrValues model.volumes;

  #
  # Primitive Queries
  #

  all = volumes;

  ids = model: attrNames model.volumes;

  count = model: builtins.length (all model);

  has = model: id: hasAttr id model.volumes;

  get =
    model: id:
    assert builtins.isString id;
    attrByPath [ id ] null model.volumes;

  filter =
    model: predicate:
    assert builtins.isFunction predicate;
    builtins.filter predicate (all model);

  roles = model: map (volume: volume.role) (all model);

  #
  # Semantic Queries
  #

  byRole =
    model: role:
    assert builtins.isString role;
    let
      matches = filter model (volume: volume.role == role);
    in
    if matches == [ ] then null else builtins.head matches;

  byCategory =
    model: category:
    assert builtins.isString category;
    filter model (volume: volume.category == category);

  #
  # Convenience Queries
  #

  mountable = model: filter model (volume: volume.mountpoint != null);

  neededForBoot = model: filter model (volume: volume.neededForBoot);

  snapshots = model: filter model (volume: volume.snapshot);

  rollback = model: filter model (volume: volume.rollback);

  persistent =
    model:
    filter model (
      volume:
      builtins.elem volume.category [
        "state"
        "user"
      ]
    );

  #
  # Derived Facts
  #
  # Single source for layout-independent facts. These read only
  # model.volumes, model.layout and model.platform, never
  # model.persistence, so modules may use them in conditions on
  # persistence.state.
  #

  # The volume that receives feature-declared state, or null.
  stateVolume = model: byRole model model.layout.stateRole;

  # The rollback template volume, or null.
  template =
    model:
    let
      matches = byCategory model "template";
    in
    if matches == [ ] then null else builtins.head matches;

  # The volume holding pre-rollback archives, or null.
  snapshotVolume =
    model:
    let
      matches = byCategory model "snapshot";
    in
    if matches == [ ] then null else builtins.head matches;

  # True when / is recreated on every boot.
  ephemeralRoot = model: builtins.any (volume: volume.mountpoint == "/") (rollback model);

  # LUKS mapping holding the root filesystem, or null when unencrypted.
  luksName =
    model:
    let
      inherit (model.platform) encryption;
    in
    if encryption.enable then encryption.label else null;
in
{
  inherit
    all
    ids
    count
    has
    get
    filter
    roles
    byRole
    byCategory
    mountable
    neededForBoot
    snapshots
    rollback
    persistent
    stateVolume
    template
    snapshotVolume
    ephemeralRoot
    luksName
    ;
}
