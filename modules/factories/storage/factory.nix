{ config, ... }:
{
  flake.factory.storage =
    let
      inherit (config.flake.library.storage)
        layouts
        normalize
        query
        transform
        types
        validate
        ;
    in
    {
      version = 1;

      inherit
        layouts
        normalize
        query
        transform
        types
        validate
        ;
    };
}
