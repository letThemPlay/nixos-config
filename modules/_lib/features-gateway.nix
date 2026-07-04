{ config, lib, ... }:
let
  requestedFeatures = config.modules.features.activeList or [ ];

  resolveFeature =
    name:
    lib.optional (builtins.hasAttr name config.modules.features.registry)
      config.modules.features.registry.${name};
in
{
  imports = [ ../features/_registry.nix ] ++ (builtins.concatMap resolveFeature requestedFeatures);
}
