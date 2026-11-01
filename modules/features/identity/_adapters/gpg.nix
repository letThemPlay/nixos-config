{ lib }:

#
# Each user's OpenPGP setup as plain data, for users with keys, a
# signing key or a smartcard. The identity-home module resolves the
# pinentry package and applies it; graphical picks a GUI pinentry.
#
{ model, graphical }:

let
  hasGpg = user: user.gpg.keys != [ ] || user.gpg.signingKey != null || user.gpg.smartcard;
in
{
  users = lib.mapAttrs (_: user: {
    publicKeys = map (source: {
      inherit source;
      trust = 5;
    }) user.gpg.keys;

    inherit (user.gpg) ssh signingKey;

    pinentry = if graphical then "pinentry-gnome3" else "pinentry-curses";
  }) (lib.filterAttrs (_: hasGpg) model.users);

  # The card needs its device rules on the host.
  smartcard = builtins.any (user: user.gpg.smartcard) (builtins.attrValues model.users);
}
