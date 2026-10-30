#
# The btrfs backend: see the backend contract in ../../default.nix.
#
{ lib, storage }:
{
  disko = import ./disko.nix { inherit lib; };

  rollback = import ./rollback.nix { inherit lib storage; };
}
