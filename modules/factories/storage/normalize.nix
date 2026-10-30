_: {
  flake.library.storageNormalize =
    {
      config,
      lib,
      ...
    }:

    let
      inherit (lib)
        mapAttrs
        recursiveUpdate
        ;

      inherit (config.flake.library)
        storageLayouts
        ;
    in

    cfg:

    let
      layout = storageLayouts.${cfg.layout};

      mergedVolumes = recursiveUpdate layout.volumes cfg.volumes;

      normalizedVolumes = mapAttrs (
        id: volume:
        volume
        // {
          inherit id;

          backend = if volume.backend == null then cfg.backend else volume.backend;
        }
      ) mergedVolumes;

    in
    {
      version = layout.version or 1;

      layout = {
        name = cfg.layout;

        inherit (layout)
          description
          requiredRoles
          ;
      };

      backend = cfg.backend;

      volumes = normalizedVolumes;

      persistence = cfg.persistence;
    };
}
