{
  lib,
  network,
  diagnostics,
}:
let
  inherit (network) query;

  inherit (diagnostics)
    combine
    duplicateStrings
    mkDiagnostic
    mkResult
    ;

  supportedProfileVersions = [ 1 ];

  inherit (lib)
    concatStringsSep
    filter
    hasInfix
    optional
    ;

  supportedText = registry: concatStringsSep ", " (builtins.attrNames registry);

  profile =
    model:

    mkResult (
      optional (!model.profile.known) (mkDiagnostic {
        severity = "error";
        code = "network.profile.unknown";
        target = model.profile.name;
        path = [ "profile" ];
        message = "Unknown network profile '${model.profile.name}' (known: ${supportedText network.profiles}).";
      })

      ++
        optional (model.profile.known && !builtins.elem model.profile.version supportedProfileVersions)
          (mkDiagnostic {
            severity = "error";
            code = "network.profile.version.unsupported";
            target = model.profile.name;
            path = [
              "profile"
              "version"
            ];
            message = "Profile '${model.profile.name}' has schema version ${toString model.profile.version}; supported: ${
              lib.concatMapStringsSep ", " toString supportedProfileVersions
            }.";
          })
    );

  #
  # The link backend must be registered, and so must the wireless
  # backend when a wireless link is enabled.
  #
  backend =
    model:

    mkResult (
      optional (!builtins.hasAttr model.backend network.backends) (mkDiagnostic {
        severity = "error";
        code = "network.backend.unknown";
        target = model.backend;
        path = [ "backend" ];
        message = "Unknown network backend '${model.backend}' (known: ${supportedText network.backends}).";
      })

      ++
        optional (query.hasWireless model && !builtins.hasAttr model.wireless.backend network.wireless)
          (mkDiagnostic {
            severity = "error";
            code = "network.wireless.backend.unknown";
            target = model.wireless.backend;
            path = [
              "wireless"
              "backend"
            ];
            message = "Unknown wireless backend '${model.wireless.backend}' (known: ${supportedText network.wireless}).";
          })

      ++ optional (model.wireless.ui && !query.hasWireless model) (mkDiagnostic {
        severity = "warning";
        code = "network.wireless.ui.unused";
        target = model.wireless.backend;
        path = [
          "wireless"
          "ui"
        ];
        message = "The wireless UI is enabled, but no wireless link is.";
      })
    );

  links =
    model:

    let
      enabled = query.enabled model;

      duplicate =
        {
          severity,
          code,
          what,
        }:
        values:
        map (
          value:
          mkDiagnostic {
            inherit severity code;
            target = value;
            path = [ "links" ];
            message = "${what} '${value}' is used by more than one link.";
          }
        ) (duplicateStrings values);
    in

    mkResult (
      duplicate {
        severity = "error";
        code = "network.link.match.duplicate";
        what = "Interface match";
      } (map (link: link.match) enabled)

      ++ duplicate {
        severity = "warning";
        code = "network.link.routeMetric.duplicate";
        what = "Route metric";
      } (map (link: toString link.routeMetric) enabled)

      ++ optional (enabled == [ ]) (mkDiagnostic {
        severity = "warning";
        code = "network.links.none";
        target = model.profile.name;
        path = [ "links" ];
        message = "No network link is enabled.";
      })
    );

  dns =
    model:

    let
      inherit (model) dns;

      # Without a TLS name the resolver cannot verify a fallback.
      unverifiedFallback = filter (server: !hasInfix "#" server) dns.fallback;
    in

    mkResult (
      optional (!dns.known) (mkDiagnostic {
        severity = "error";
        code = "network.dns.provider.unknown";
        target = dns.provider;
        path = [
          "dns"
          "provider"
        ];
        message = "Unknown DNS provider '${dns.provider}' (known: ${supportedText network.providers}).";
      })

      ++ optional (dns.known && dns.servers == [ ]) (mkDiagnostic {
        severity = "error";
        code = "network.dns.servers.empty";
        target = toString dns.provider;
        path = [
          "dns"
          "servers"
        ];
        message = "No DNS servers: select a provider or set dns.servers.";
      })

      ++ optional (dns.dnsOverTls == "yes" && unverifiedFallback != [ ]) (mkDiagnostic {
        severity = "warning";
        code = "network.dns.fallback.insecure";
        target = concatStringsSep ", " unverifiedFallback;
        path = [
          "dns"
          "fallback"
        ];
        message = "Fallback DNS ${concatStringsSep ", " unverifiedFallback} has no TLS name, so DNS-over-TLS cannot verify it.";
      })
    );

  #
  # Every tunnel needs a known backend and owns its interface: no link
  # may match it and no other tunnel may use it. Tailscale tunnels share
  # the daemon's interface and its tags. Auth keys are checked by
  # ltp.secrets.
  #
  tunnels =
    model:

    let
      every = query.tunnels model;

      known = filter (tunnel: tunnel.known) every;

      tailscale = query.tunnelsByBackend model "tailscale";

      wireguard = query.tunnelsByBackend model "wireguard";

      # Tailscale tunnels are modes of one daemon, so its interface counts once.
      owners =
        filter (tunnel: tunnel.backend != "tailscale") known
        ++ lib.take 1 (filter (tunnel: tunnel.known) tailscale);

      interfaces = map (tunnel: tunnel.interface) owners;

      error =
        code: target: path: message:
        mkDiagnostic {
          severity = "error";
          inherit code target message;
          path = [ "tunnels" ] ++ path;
        };

      claiming =
        tunnel:
        map (
          link:
          error "network.tunnel.interface.managed" link.id [ tunnel.name "interface" ]
            "Link '${link.id}' (match '${link.match}') also matches tunnel interface '${tunnel.interface}'; networkd would manage the tunnel."
        ) (filter (link: query.matchesGlob link.match tunnel.interface) (query.enabled model));

      badTags = filter (tag: builtins.match "[a-z0-9-]+" tag == null) model.tailscale.tags;

      autostarted = filter (tunnel: tunnel.autostart) every;

      # Each conflicting pair of autostarted tunnels, once.
      autostartClashes = lib.concatMap (
        tunnel:
        map
          (other: {
            inherit tunnel other;
          })
          (filter (other: other.name > tunnel.name && builtins.elem other.unit tunnel.conflicts) autostarted)
      ) autostarted;
    in

    mkResult (
      map (
        tunnel:
        error "network.tunnel.backend.unknown" tunnel.backend
          [
            tunnel.name
            "backend"
          ]
          "Tunnel '${tunnel.name}' has unknown backend '${tunnel.backend}' (known: ${supportedText network.tunnels})."
      ) (filter (tunnel: !tunnel.known) every)

      ++ lib.concatMap claiming owners

      ++ map (
        interface:
        error "network.tunnel.interface.duplicate" interface [
          "interface"
        ] "Interface '${interface}' is used by more than one tunnel."
      ) (duplicateStrings interfaces)

      # The kernel's limit (IFNAMSIZ less the terminator).
      ++ map (
        tunnel:
        error "network.tunnel.interface.tooLong" tunnel.interface [
          tunnel.name
          "interface"
        ] "Tunnel interface '${tunnel.interface}' is longer than 15 characters."
      ) (filter (tunnel: builtins.stringLength tunnel.interface > 15) owners)

      ++ lib.optionals (tailscale != [ ]) (
        map (
          tag:
          mkDiagnostic {
            severity = "error";
            code = "network.tailscale.tag.invalid";
            target = tag;
            path = [
              "tailscale"
              "tags"
            ];
            message = "Tailscale tag '${tag}' must be lowercase letters, digits and dashes, without the tag: prefix.";
          }
        ) badTags
      )

      ++ map (
        { tunnel, other }:
        mkDiagnostic {
          severity = "warning";
          code = "network.tunnel.autostart.conflict";
          target = "${tunnel.name}, ${other.name}";
          path = [ "tunnels" ];
          message = "Tunnels '${tunnel.name}' and '${other.name}' both start at boot but cannot run together; only one stays up.";
        }
      ) autostartClashes

      # Wireguard tunnels are networkd netdevs.
      ++ lib.optional (wireguard != [ ] && model.backend != "networkd") (mkDiagnostic {
        severity = "error";
        code = "network.tunnel.wireguard.backend";
        target = model.backend;
        path = [ "backend" ];
        message = "Wireguard tunnels are networkd netdevs, but the link backend is '${model.backend}'.";
      })

      ++ map (
        tunnel:
        error "network.tunnel.wireguard.peers.none" tunnel.name [
          tunnel.name
          "wireguard"
          "peers"
        ] "Wireguard tunnel '${tunnel.name}' has no peers."
      ) (filter (tunnel: tunnel.wireguard.peers == { }) wireguard)

      ++ map (
        tunnel:
        error "network.tunnel.wireguard.addresses.none" tunnel.name [
          tunnel.name
          "wireguard"
          "addresses"
        ] "Wireguard tunnel '${tunnel.name}' has no addresses."
      ) (filter (tunnel: tunnel.wireguard.addresses == [ ]) wireguard)
    );

  all =
    model:

    combine [
      (profile model)
      (backend model)
      (links model)
      (dns model)
      (tunnels model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    profile
    backend
    links
    dns
    tunnels
    all
    ;
}
