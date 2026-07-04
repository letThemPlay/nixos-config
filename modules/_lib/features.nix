{ lib, config, ... }:
let
  resolveFeature =
    name:
    lib.optional (builtins.hasAttr name config.modules.features.registry)
      config.modules.features.registry.${name};
in
{
  resolveFeatures = requestedFeatures: lib.concatMap resolveFeature requestedFeatures;
}
