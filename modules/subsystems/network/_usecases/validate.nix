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
in

rec {

  inherit
    mkDiagnostic
    mkResult
    ;

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
  # The overlay owns its interface, needs a known backend and advertises
  # well-formed tags; its auth key is checked by ltp.secrets. Checked
  # only when the overlay is enabled.
  #
  overlay =
    model:

    let
      inherit (model) overlay;

      diagnostic =
        code: target: path: message:
        mkDiagnostic {
          severity = "error";
          inherit code target message;
          path = [ "overlay" ] ++ path;
        };

      claiming = filter (link: query.matchesGlob link.match overlay.interface) (query.enabled model);

      badTags = filter (tag: builtins.match "[a-z0-9-]+" tag == null) overlay.tags;
    in

    mkResult (
      lib.optionals overlay.enable (
        optional (!overlay.known) (
          diagnostic "network.overlay.backend.unknown" overlay.backend [
            "backend"
          ] "Unknown overlay backend '${overlay.backend}' (known: ${supportedText network.overlays})."
        )

        ++ map (
          link:
          diagnostic "network.overlay.interface.managed" link.id [ "interface" ]
            "Link '${link.id}' (match '${link.match}') also matches overlay interface '${overlay.interface}'; networkd would manage the tunnel."
        ) claiming

        ++ map (
          tag:
          diagnostic "network.overlay.tag.invalid" tag [
            "tags"
          ] "Overlay tag '${tag}' must be lowercase letters, digits and dashes, without the tag: prefix."
        ) badTags
      )
    );

  all =
    model:

    combine [
      (profile model)
      (backend model)
      (links model)
      (dns model)
      (overlay model)
    ];

}
