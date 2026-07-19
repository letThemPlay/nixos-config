_: {
  flake.library.storage.transform =
    {
      config,
      ...
    }:

    let
      inherit (config.flake.library.storage.transform)
        btrfs
        ;
    in
    {
      version = 1;

      inherit
        btrfs
        ;
    };
}
