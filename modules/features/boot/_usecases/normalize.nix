{ boot }:

#
# cfg is the ltp.boot option set, or any attrset of the same shape.
# storage is the published storage facts (ltp.storage.facts) as plain
# data; only luksName is read. No module system is required.
#
{ cfg, storage }:

let
  # Without an explicit choice, Secure Boot decides the loader.
  name =
    if cfg.loader != null then
      cfg.loader
    else if cfg.secureBoot.enable then
      "lanzaboote"
    else
      "systemd-boot";

  entry = boot.loaders.${name} or null;
in
{
  loader = {
    inherit name;

    known = entry != null;

    secureBoot = if entry == null then false else entry.secureBoot;
  };

  inherit (cfg) generations;

  secureBoot = {
    inherit (cfg.secureBoot) enable pkiBundle;
  };

  tpmUnlock = {
    inherit (cfg.tpmUnlock) enable;

    inherit (storage) luksName;
  };
}
