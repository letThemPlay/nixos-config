{ config, ... }:
{
  flake.library.storage = {
    types = config.flake.library.storageTypes;
    layouts = config.flake.library.storageLayouts;
    normalize = config.flake.library.storageNormalize;
    query = config.flake.library.storageQuery;
    validate = config.flake.library.storageValidate;
    transform = config.flake.library.storageTransform;
  };
}
