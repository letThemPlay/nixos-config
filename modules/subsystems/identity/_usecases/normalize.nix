{ lib }:
let
  inherit (lib)
    concatMap
    filter
    filterAttrs
    mapAttrs
    optional
    unique
    ;
in

#
# cfg is the ltp.identity option set, or any attrset of the same
# shape. storage is the published storage facts (ephemeralRoot,
# statePath). context supplies the host's catalogues as plain data:
#
#   hasPackage : package name -> bool
#
# The feature names come from cfg.knownFeatures. No module system is
# required.
#
{
  cfg,
  storage,
  context,
}:

let
  ephemeral = storage.ephemeralRoot && storage.statePath != null;

  # Null means automatic: per-user hash files on the state volume.
  passwordDirectory =
    if cfg.passwordDirectory != null then
      cfg.passwordDirectory
    else if ephemeral then
      "${storage.statePath}/secrets/passwords"
    else
      null;

  enabled = filterAttrs (_: user: user.enable) cfg.users;

  users = mapAttrs (
    name: user:
    removeAttrs user [ "enable" ]
    // {
      username = name;

      groups = [
        "video"
        "audio"
      ]
      ++ user.extraGroups
      ++ optional user.admin "wheel";

      passwordFile = if passwordDirectory == null then null else "${passwordDirectory}/${name}";
    }
  ) enabled;

  requestedPackages = unique (concatMap (user: user.extraPackages) (builtins.attrValues users));
in
{
  inherit
    users
    ephemeral
    passwordDirectory
    ;

  inherit (storage) statePath;

  known = {
    features = cfg.knownFeatures;

    packages = filter context.hasPackage requestedPackages;
  };
}
