{ config, ... }:
{
  flake.library.storageTransform = {
    btrfs = config.flake.library.storageTransformBtrfs;
  };
}
