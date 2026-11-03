{ lib }:

#
# users.users entries as plain data. The login shell is set by the shell
# feature from the user's `shell`.
#
{ model }:

{
  users = lib.mapAttrs (_: user: {
    isNormalUser = true;

    description = user.fullName;

    extraGroups = user.groups;

    inherit (user) passwordFile;
  }) model.users;
}
