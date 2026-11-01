{ lib }:

#
# Nix settings as plain data; the nix module resolves the package and
# applies the rest to nix.settings and nix.gc.
#
{ model }:

let
  caches = lib.attrValues model.caches;
in
{
  settings = {
    experimental-features = model.experimentalFeatures;

    auto-optimise-store = model.optimiseStore;

    # NixOS appends its own default (the official cache).
    substituters = map (cache: cache.url) caches;

    trusted-public-keys = map (cache: cache.key) caches;
  };

  gc = {
    automatic = model.gc.enable;

    inherit (model.gc) dates;

    options = "--delete-older-than ${model.gc.olderThan}";
  };
}
