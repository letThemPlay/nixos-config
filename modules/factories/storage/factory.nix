{ config, ... }:
{
  flake.factory.storage =
    let
      inherit (config.flake.library.storage)
        layouts
        normalize
        query
        backends
        preservation
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
        backends
        preservation
        types
        validate
        ;
    };
}
