{ lib, network }:
let
  inherit (lib)
    attrNames
    genAttrs
    unique
    ;

  networkProfiles = network.profiles;
  networkProviders = network.providers;
  networkTypes = network.types;

  orDefault = value: default: if value == null then default else value;
in

#
# cfg is the ltp.network option set, or any attrset of the same
# shape: profile, backend, wireless.backend, links (partial
# overrides), dns and overlay. No module system is required.
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
    networkTypes.applyLinkOverride (networkTypes.linkDefaults id // (profileLinks.${id} or { })) (
      cfg.links.${id} or { }
    )
    // {
      inherit id;
    }
  );

  inherit (cfg) dns;

  providerKnown = dns.provider == null || builtins.hasAttr dns.provider networkProviders;

  # No provider, or an unknown one, supplies nothing.
  provider = if dns.provider == null then { } else networkProviders.${dns.provider} or { };

  dnsOverTls = orDefault dns.dnsOverTls (provider.dnsOverTls or "yes");

  tlsName = provider.tlsName or null;

  # The TLS name lets the resolver verify the provider's certificate.
  providerServers = map (
    server: if tlsName != null && dnsOverTls != "no" then "${server}#${tlsName}" else server
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

  overlay = {
    inherit (cfg.overlay)
      enable
      backend
      interface
      routing
      tags
      acceptDns
      ;

    known = network.overlays ? ${cfg.overlay.backend};

    authKey = {
      inherit (cfg.overlay.authKey) secret;

      available = builtins.pathExists (network.secretsDir + "/${cfg.overlay.authKey.secret}.age");
    };
  };

  dns = {
    inherit (dns) provider;

    known = providerKnown;

    # Host servers are taken as written.
    servers = orDefault dns.servers providerServers;

    inherit dnsOverTls;

    dnssec = orDefault dns.dnssec false;

    fallback = orDefault dns.fallback (provider.fallback or [ ]);
  };
}
