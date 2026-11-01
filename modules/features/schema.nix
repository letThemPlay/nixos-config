{ lib, ... }:
{
  options.flake.features = lib.mkOption {
    #
    # raw: values are stored untouched. `anything` would wrap functions
    # and merge their results, resolving mkIf/mkMerge returned by
    # core functions at call time instead of in the consumer.
    #
    type = lib.types.lazyAttrsOf lib.types.raw;

    default = { };

    description = "Feature cores and their shared kernel, one definition per attribute.";
  };
}
