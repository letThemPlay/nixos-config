{ lib, secrets }:
let
  inherit (lib) any hasPrefix mapAttrs;
in

#
# cfg is the ltp.secrets option set. hostName is the host's name and
# sshd whether services.openssh creates the host keys. keys, rules and
# dir default to the repository's secrets/ (tests pass their own). No
# module system is required.
#
{
  cfg,
  hostName,
  sshd,
  keys ? secrets.keys,
  rules ? secrets.rules,
  dir ? secrets.dir,
}:

let
  hostKey = keys.hosts.${hostName} or null;
in
{
  files = mapAttrs (
    name: file:
    let
      rule = rules."${name}.age" or null;
    in
    {
      inherit (file) owner group mode;

      source = dir + "/${name}.age";

      exists = builtins.pathExists (dir + "/${name}.age");

      hasRule = rule != null;

      forHost = rule != null && hostKey != null && builtins.elem hostKey rule.publicKeys;
    }
  ) cfg.files;

  host = {
    name = hostName;
    key = hostKey;
  };

  identity = {
    paths = cfg.identityPaths;

    sshHostKey = any (hasPrefix "/etc/ssh/ssh_host_") cfg.identityPaths;

    provided = sshd || cfg.hostKeyProvisioned;
  };
}
