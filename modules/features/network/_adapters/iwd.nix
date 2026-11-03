{ network }:

#
# The iwd wireless backend. Addresses come from the link backend, so
# iwd only associates.
#
{ model }:

{
  active = network.query.hasWireless model;

  settings = {
    Network = {
      EnableIPv6 = false;
      RoutePriorityOffset = 300;
    };

    Settings.AutoConnect = true;
  };

  # Its graphical UI (a pkgs attribute name).
  ui = "iwgtk";

  # Known networks and their passphrases.
  state.directories = [ "/var/lib/iwd" ];
}
