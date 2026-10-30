{ config, ... }:
{
  flake.library.storageTransformBtrfs = {
    disko = config.flake.library.storageTransformBtrfsDisko;
    preservation = config.flake.library.storageTransformBtrfsPreservation;
  };
}
