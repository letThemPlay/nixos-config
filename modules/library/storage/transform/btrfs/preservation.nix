{ lib, ... }:
{
  flake.library.storageTransformBtrfsPreservation =
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
    # Produces NixOS configuration for nix-community/preservation.
    #
    # model.persistence already contains layout, host and
    # feature-declared entries, grouped by volume.
    #
    { model }:

    let
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

    in
    {
      preservation = {
        enable = preserveAt != { };

        inherit preserveAt;
      };
    };
}
