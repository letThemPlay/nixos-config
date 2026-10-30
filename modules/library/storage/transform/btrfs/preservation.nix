_: {
  flake.library.storageTransformBtrfsPreservation =
    {
      lib,
      ...
    }:

    { model }:

    let
      inherit (lib)
        mapAttrs
        ;

      preserveAt = mapAttrs (
        volumeId: policy:

        let
          volume = model.volumes.${volumeId};
        in
        {
          persistentStoragePath = volume.mountpoint;

          directories = policy.directories;

          files = policy.files;
        }
      ) model.persistence;
    in
    {
      inherit preserveAt;
    };
}
