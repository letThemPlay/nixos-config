#
# DNS providers, selected with ltp.network.dns.provider. Servers are
# bare addresses; normalize appends the TLS name.
#
_: {

  cloudflare = {
    description = ''
      Cloudflare public resolver.
    '';

    servers = [
      "1.1.1.1"
      "1.0.0.1"
    ];

    tlsName = "cloudflare-dns.com";

    dnsOverTls = "yes";

    # Verified over TLS like the primary servers.
    fallback = [ "8.8.8.8#dns.google" ];
  };

  nextdns = {
    description = ''
      NextDNS, filtered by profile 965e8b.
    '';

    servers = [
      "45.90.28.0"
      "2a07:a8c0::"
      "45.90.30.0"
      "2a07:a8c1::"
    ];

    tlsName = "965e8b.dns.nextdns.io";

    dnsOverTls = "yes";

    fallback = [ ];
  };

  controld = {
    description = ''
      Control D, filtered by resolver 1cn20by0pm5.
    '';

    servers = [
      "76.76.2.22"
      "2606:4700:3032::22"
      "76.76.10.22"
      "2606:4700:3034::22"
    ];

    tlsName = "1cn20by0pm5.dns.controld.com";

    dnsOverTls = "yes";

    fallback = [ ];
  };

}
