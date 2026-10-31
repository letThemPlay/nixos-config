_: {
  #
  # Wireless UI. The links and iwd itself come from ltp.network; hosts
  # with this feature select a profile with a wireless link.
  #
  flake.nixosModules.wifi =
    { pkgs, ... }:
    {
      config.environment.systemPackages = [ pkgs.iwgtk ];
    };
}
