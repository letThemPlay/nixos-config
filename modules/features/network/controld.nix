_: {
  flake.nixosModules.controld-dns = { lib, ... }: {
    config = {
      services.resolved = {
        enable = true;
        settings.Resolve = lib.mkForce {
          DNSOverTLS = true;

          DNS = map (i: "${i}#1cn20by0pm5.dns.controld.com") [
            "76.76.2.22"
            "2606:4700:3032::22"
            "76.76.10.22"
            "2606:4700:3034::22"
          ];

          FallbackDNS = [ ];
        };
      };

      systemd.network.networks = lib.mapAttrs (
        _: _: {
          networkConfig.DNS = lib.mkForce [ ];
        }
      );
    };
  };
}
