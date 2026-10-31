{ lib, network }:
let
  inherit (lib)
    attrNames
    filterAttrs
    genAttrs
    unique
    ;

  networkProfiles = network.profiles;
  networkProviders = network.providers;
  networkTypes = network.types;

  # An override only replaces the fields it sets.
  setFields = filterAttrs (_: value: value != null);

  orDefault = value: default: if value == null then default else value;
in

#
# cfg is the ltp.network option set, or any attrset of the same
# shape: profile, backend, wireless.backend, links (partial
# overrides) and dns. No module system is required.
#
cfg:

let
  known = builtins.hasAttr cfg.profile networkProfiles;

  profile =
    networkProfiles.${cfg.profile} or {
      version = 1;
      description = "";
    };

  profileLinks = profile.links or { };

  #
  # defaults <- profile link <- host override. An attribute that
  # exists only in the overrides adds a new link. An unknown profile
  # contributes nothing; validation reports it.
  #
  links = genAttrs (unique (attrNames profileLinks ++ attrNames cfg.links)) (
    id:
    networkTypes.linkDefaults id
    // (profileLinks.${id} or { })
    // setFields (cfg.links.${id} or { })
    // {
      inherit id;
    }
  );

  inherit (cfg) dns;

  providerKnown = dns.provider == null || builtins.hasAttr dns.provider networkProviders;

  # No provider, or an unknown one, supplies nothing.
  provider = if dns.provider == null then { } else networkProviders.${dns.provider} or { };

  dnsOverTLS = orDefault dns.dnsOverTLS (provider.dnsOverTLS or "yes");

  tlsName = provider.tlsName or null;

  # The TLS name lets the resolver verify the provider's certificate.
  providerServers = map (
    server: if tlsName != null && dnsOverTLS != "no" then "${server}#${tlsName}" else server
  ) (provider.servers or [ ]);
in
{
  profile = {
    name = cfg.profile;

    inherit known;

    version = profile.version or 1;

    inherit (profile) description;
  };

  inherit (cfg) backend;

  inherit links;

  wireless = {
    inherit (cfg.wireless) backend;
  };

  dns = {
    inherit (dns) provider;

    known = providerKnown;

    # Host servers are taken as written.
    servers = orDefault dns.servers providerServers;

    inherit dnsOverTLS;

    dnssec = orDefault dns.dnssec false;

    fallback = orDefault dns.fallback (provider.fallback or [ ]);
  };
}
