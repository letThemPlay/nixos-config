{ lib }:

#
# Each user's xdg.userDirs as plain data. createDirectories makes the
# folders during activation, since nothing else creates them: apps only
# make the one they need, when they first need it.
#
{ model }:

{
  users = lib.mapAttrs (_: _: {
    enable = true;
    createDirectories = true;
  }) model.users;
}
