{ lib }:

#
# users.users entries as plain data. The shell is a package name; the
# identity module resolves it from pkgs.
#
{ model }:

{
  users = lib.mapAttrs (_: user: {
    isNormalUser = true;

    description = user.fullName;

    extraGroups = user.groups;

    inherit (user) shell passwordFile;
  }) model.users;
}
