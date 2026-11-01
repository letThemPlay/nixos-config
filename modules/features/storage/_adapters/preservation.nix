{ lib }:
let
  inherit (lib)
    filterAttrs
    isString
    mapAttrs'
    nameValuePair
    ;

  #
  # Unset typed settings are null; preservation applies its own
  # defaults when a key is absent.
  #
  clean = entry: if isString entry then entry else filterAttrs (_: value: value != null) entry;
in

#
# Produces the nix-community/preservation preserveAt set as plain
# data; the storage module applies it.
#
# model.persistence already contains layout, host and
# feature-declared entries, grouped by volume.
#
{ model }:

{
  preserveAt = mapAttrs' (
    volumeId: policy:

    let
      volume = model.volumes.${volumeId};
    in
    nameValuePair volume.mountpoint {
      directories = map clean policy.directories;

      files = map clean policy.files;
    }
  ) model.persistence;
}
