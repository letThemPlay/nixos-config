#
# The daemon's tags, routes and auth key secret are ltp.network.tailscale
# options; exit-node tunnels are host settings.
#
_: {
  ltp.network.tunnels.tailnet = {
    backend = "tailscale";
    autostart = true;
  };
}
