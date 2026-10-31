_:

#
# Machine identity and user database on an ephemeral root.
#
# When / is recreated on every boot, /etc is lost with it. This keeps
# the machine-id, preserves the userborn user database and makes users
# declarative. Inactive unless the root is ephemeral.
#
{ model }:

let
  inherit (model) statePath;

  userbornState = "/var/lib/userborn";
in
{
  active = model.ephemeral;

  state = {
    directories = [
      {
        directory = userbornState;
        inInitrd = true;
      }
    ];

    files = [
      {
        file = "/etc/machine-id";
        how = "symlink";
        inInitrd = true;
        configureParent = true;
      }
    ];
  };

  #
  # userborn keeps passwd, group and shadow in its preserved state
  # directory and links them into /etc.
  #
  userborn = {
    enable = true;

    passwordFilesLocation = userbornState;
  };

  #
  # First boot: seed the persistent machine-id as "uninitialized" so
  # ConditionFirstBoot holds, then commit the generated ID to the
  # persistent volume instead of /etc.
  #
  machineIdSeed = {
    "/sysroot${statePath}/etc/machine-id".f = {
      argument = "uninitialized";
    };
  };

  machineIdCommit = {
    unitConfig.ConditionPathIsMountPoint = [
      ""
      "${statePath}/etc/machine-id"
    ];

    serviceConfig.ExecStart = [
      ""
      "systemd-machine-id-setup --commit --root ${statePath}"
    ];
  };

  #
  # Password changes made at runtime are lost with /etc. Users are
  # declarative; this also enables the NixOS assertion that a wheel
  # user or root has a password.
  #
  mutableUsers = false;
}
