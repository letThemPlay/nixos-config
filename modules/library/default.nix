{ lib, ... }:
{
  options.flake.library = lib.mkOption {
    #
    # raw: values are stored untouched. `anything` would wrap functions
    # and merge their results, resolving mkIf/mkMerge returned by
    # library functions at call time instead of in the consumer.
    #
    type = lib.types.lazyAttrsOf lib.types.raw;

    default = { };

    description = "Custom library functions, one definition per attribute.";
  };
}
