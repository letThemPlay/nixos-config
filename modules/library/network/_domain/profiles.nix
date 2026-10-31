#
# Network profiles: the links a kind of host has. Hosts pick one with
# ltp.network.profile and override single fields with
# ltp.network.links.<id>.
#
_:
let
  wired = {
    kind = "wired";
    match = "en*";
    priority = 20;
    routeMetric = 1024;
  };

  wireless = {
    kind = "wireless";
    match = "wl*";
    priority = 25;
    routeMetric = 2048;
  };
in
{

  wired = {
    version = 1;

    description = ''
      A single wired link configured by DHCP.
    '';

    links = { inherit wired; };
  };

  laptop = {
    version = 1;

    description = ''
      Wired and wireless links; wired is preferred when both are up.
    '';

    links = { inherit wired wireless; };
  };

}
