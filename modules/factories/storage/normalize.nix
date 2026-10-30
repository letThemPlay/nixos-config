{ config, lib, ... }:
{
  flake.library.storageNormalize =
    let
      inherit (lib)
        mapAttrs
        ;

      inherit (config.flake.library)
        storageLayouts
        ;
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

      layout = storageLayouts.${cfg.layout} or {
        version = 1;
        description = "";
        requiredRoles = [ ];
      };

      backend = cfg.filesystem.type;

      normalizedVolumes = mapAttrs (
        id: volume:
        volume
        // {
          inherit id;

          backend = if volume.backend == null then backend else volume.backend;
        }
      ) cfg.volumes;

    in
    {
      version = 1;

      layout = {
        name = cfg.layout;

        inherit known;

        version = layout.version or 1;

        inherit (layout)
          description
          requiredRoles
          ;
      };

      inherit (cfg) renderer;

      inherit backend;

      volumes = normalizedVolumes;

      persistence = cfg.persistence.policy;

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
