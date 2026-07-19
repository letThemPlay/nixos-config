_: {
  flake.factory.storage =
    {
      lib,
      ...
    }:
    let
      inherit (lib)
        attrValues
        filterAttrs
        mapAttrs
        ;
    in
    rec {

      normalize = cfg: ...;

      query = {

        get = model: name: ...;

        all = model: attrValues model.volumes;

        mounted = model:
          filterAttrs (_: v: v.mountpoint != null) model.volumes;

        byKind = model: kind:
          filterAttrs (_: v: v.kind == kind) model.volumes;
      };

      render = {
        # Empty for now
      };

    };
}
