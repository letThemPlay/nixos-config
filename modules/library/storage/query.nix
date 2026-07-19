_: {
  flake.library.storage.query =
    { lib, ... }:

    let
      inherit (lib)
        attrByPath
        attrNames
        attrValues
        filter
        hasAttr
        map
        ;

      #
      # Internal helper.
      #
      # Always work with the normalized list representation.
      #
      volumes = model: attrValues model.volumes;

    in

    rec {

      #
      # Primitive Queries
      #

      all = model: volumes model;

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

    };
}
