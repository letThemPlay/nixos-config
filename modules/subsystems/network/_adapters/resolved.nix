_:

#
# Produces services.resolved.settings as plain data; the network
# module applies it.
#
{ model }:

{
  Resolve = {
    DNS = model.dns.servers;

    DNSOverTLS = model.dns.dnsOverTLS;

    DNSSEC = model.dns.dnssec;

    FallbackDNS = model.dns.fallback;
  };
}
