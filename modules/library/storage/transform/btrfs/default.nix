{ config, ... }:
{
  flake.library.storageTransformBtrfs = {
    disko = config.flake.library.storageTransformBtrfsDisko;
    rollback = config.flake.library.storageTransformBtrfsRollback;
  };
}
