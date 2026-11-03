{ lib, nix }:

#
# cfg is the ltp.nix option set, or any attrset of the same shape.
# hasPackage tells whether a pkgs attribute path exists; the nix module
# supplies it. No module system is required.
#
{
  cfg,
  hasPackage ? _: true,
}:

{
  package = {
    path = cfg.package;
    known = hasPackage cfg.package;
  };

  inherit (cfg) experimentalFeatures optimiseStore gc;

  # An added cache replaces the default with the same name.
  caches = (if cfg.defaultCaches then nix.defaultCaches else { }) // cfg.caches;

  # Defaults first, then added libraries; each path once.
  ld = {
    inherit (cfg.ld) enable;

    libraries =
      map
        (path: {
          inherit path;
          known = hasPackage path;
        })
        (
          lib.unique ((if cfg.ld.defaultLibraries then nix.defaultLdLibraries else [ ]) ++ cfg.ld.libraries)
        );
  };
}
