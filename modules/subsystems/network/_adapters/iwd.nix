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

  # Known networks and their passphrases.
  state.directories = [ "/var/lib/iwd" ];
}
