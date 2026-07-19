_: {
  flake.library.storage.transform.btrfs =
    {
      config,
      ...
    }:

    let
      inherit (config.flake.library.storage.transform.btrfs)
        disko
        preservation
        rollback
        ;
    in
    {
      version = 1;

      inherit
        disko
        preservation
        rollback
        ;
    };
}
