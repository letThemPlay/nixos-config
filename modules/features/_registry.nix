{ lib, inputs, ... }: {
  options.modules.features = {
    registry = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "👑 Central Dendritic cumulative feature registry map holding merged modules.";
    };
  };

  config = {
    modules.features.registry = {
      # Individual feature modules that can be imported
      inherit (inputs.self.nixosModules) tailscale;

      # Feature Groups
      base = lib.mkMerge [
        inputs.self.nixosModules.nix-core
        inputs.self.nixosModules.network
        inputs.self.nixosModules.security
        inputs.self.nixosModules.users
        inputs.self.nixosModules.stylix
      ];

      laptop = lib.mkMerge [
        inputs.self.nixosModules.discord
        inputs.self.nixosModules.wifi
        inputs.self.nixosModules.bluetooth
      ];
    };
  };
}
