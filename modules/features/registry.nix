{ lib, ... }: {
  options.modules.features.registry = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = "👑 Central Dendritic cumulative feature registry map holding merged modules.";
  };
}
