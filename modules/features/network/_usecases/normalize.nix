{ lib, network }:
let
  inherit (lib)
    any
    attrNames
    attrValues
    filter
    filterAttrs
    genAttrs
    mapAttrs
    unique
    ;

  networkProfiles = network.profiles;
  networkProviders = network.providers;
  networkTypes = network.types;

  orDefault = value: default: if value == null then default else value;

  # Allowed IPs that make a wireguard tunnel take the default route.
  defaultRoutes = [
    "0.0.0.0/0"
    "::/0"
  ];
in

#
# cfg is the ltp.network option set, or any attrset of the same
# shape: profile, backend, wireless.backend, links (partial
# overrides), dns, tailscale and tunnels. No module system is
# required.
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

  #
  # What each tunnel backend means for a tunnel: the interface it owns
  # and whether it takes the default route. Every key of
  # network.tunnels needs an entry here; an unknown backend owns
  # nothing, and validation reports it.
  #
  tunnelShapes = {
    tailscale = tunnel: {
      inherit (cfg.tailscale) interface;
      routesAll = tunnel.tailscale.exitNode != null;
    };

    wireguard = tunnel: {
      inherit (tunnel.wireguard) interface;

      routesAll = any (peer: any (ip: builtins.elem ip defaultRoutes) peer.allowedIPs) (
        attrValues tunnel.wireguard.peers
      );
    };
  };

  shapeOf =
    tunnel:
    (tunnelShapes.${tunnel.backend} or (_: {
      interface = "";
      routesAll = false;
    })
    )
      tunnel;

  enabledTunnels = mapAttrs (name: tunnel: tunnel // shapeOf tunnel // { inherit name; }) (
    filterAttrs (_: tunnel: tunnel.enable) cfg.tunnels
  );

  unitOf = name: "ltp-tunnel-${name}.service";

  #
  # Full tunnels would fight over the default route, and tailscale
  # tunnels are modes of one daemon, so starting one stops the others.
  #
  conflict =
    a: b: (a.routesAll && b.routesAll) || (a.backend == "tailscale" && b.backend == "tailscale");

  tunnels = mapAttrs (name: tunnel: {
    inherit name;
    inherit (tunnel)
      label
      backend
      autostart
      interface
      routesAll
      wireguard
      ;

    known = network.tunnels ? ${tunnel.backend};

    unit = unitOf name;

    conflicts = map unitOf (
      filter (other: other != name && conflict tunnel enabledTunnels.${other}) (attrNames enabledTunnels)
    );

    tailscale = {
      inherit (tunnel.tailscale) exitNode;
    };

  }) enabledTunnels;
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
    inherit (cfg.wireless) backend ui;
  };

  tailscale = {
    inherit (cfg.tailscale)
      interface
      routing
      tags
      acceptDns
      acceptRoutes
      ;

    authKey = {
      inherit (cfg.tailscale.authKey) secret;
    };
  };

  inherit tunnels;

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
