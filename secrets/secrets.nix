#
# agenix rules: which keys each secret is encrypted for. After changing
# a list, re-encrypt with `agenix -r` (nix develop .#secrets).
#
let
  keys = import ./keys.nix;
in
{
  "tailscale-authkey.age".publicKeys = [
    keys.hosts.theseus
    keys.users.kelvin
  ];
}
