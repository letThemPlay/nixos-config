{ config, lib, ... }:
let
  requestedFeatures = config.modules.features.activeList or [ ];

  resolveFeature =
    name:
    lib.optional (builtins.hasAttr name config.modules.features.registry)
      config.modules.features.registry.${name};
in
{
  imports = [ ../features/registry.nix ] ++ (builtins.concatMap resolveFeature requestedFeatures);

  options.modules.features.activeList = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "👑 Clean list of feature tokens to dynamically resolve and import into this machine state.";
  };
}
