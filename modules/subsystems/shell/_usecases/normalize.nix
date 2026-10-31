{ lib, shell }:
let
  inherit (lib)
    attrValues
    filter
    mapAttrs
    unique
    ;
in

#
# cfg is the ltp.shell option set, or any attrset of the same shape.
# users is the published identity facts as plain data; only each
# user's `shell` is read. No module system is required.
#
{ cfg, users }:

let
  resolved = mapAttrs (_: user: {
    inherit (user) shell;
    known = shell.shells ? ${user.shell};
  }) users;
in
{
  # A contributed alias replaces the default with the same name.
  aliases = (if cfg.defaultAliases then shell.defaultAliases else { }) // cfg.aliases;

  users = resolved;

  shells = lib.sort lib.lessThan (
    unique (map (user: user.shell) (filter (user: user.known) (attrValues resolved)))
  );
}
