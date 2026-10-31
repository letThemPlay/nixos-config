_: {
  #
  # Joins the tailscale overlay. Its settings (tags, routing, auth key
  # secret) are ltp.network.overlay options.
  #
  flake.nixosModules.tailscale = _: {
    ltp.network.overlay.enable = true;
  };
}
