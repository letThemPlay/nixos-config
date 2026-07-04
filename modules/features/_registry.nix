{ lib, inputs, ... }: {
  options.modules.features = {
    activeList = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "👑 Clean list of feature tokens to dynamically resolve and import into this machine state.";
    };

    registry = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "👑 Central Dendritic cumulative feature registry map holding merged modules.";
    };
  };

  config = {
    modules.features.registry.laptop = lib.mkMerge [ inputs.self.nixosModules.discord ];
  };
}
