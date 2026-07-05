_: {
  flake.nixosModules.nextdns = { lib, ... }: {
    config = {
      services.resolved = {
        enable = true;
        settings.Resolve = lib.mkForce {
          DNSOverTLS = true;
          DNS = map (i: "${i}#965e8b.dns.nextdns.io") [
            "45.90.28.0"
            "2a07:a8c0::"
            "45.90.30.0"
            "2a07:a8c1::"
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
