_: {
  flake.nixosModules.network = _: {
    config = {
      networking = {
        firewall.enable = false;
        dhcpcd.enable = false;
        useDHCP = false;
        useNetworkd = true;
      };

      services.resolved = {
        enable = true;
        settings.Resolve = {
          DNSOverTLS = "yes";
          FallbackDNS = [ "8.8.8.8" ];
        };
      };
    };
  };
}
