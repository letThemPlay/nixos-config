{ config, lib, ... }:
let
  network = config.flake.subsystems.network;

  inherit (config.flake.nixosModules) network-api;

  #
  # Host settings are evaluated through the real API module so option
  # defaults apply exactly as they do on a host.
  #
  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        network-api
        { ltp.network = settings; }
      ];
    }).config.ltp.network;

  modelOf = settings: network.normalize (evalCfg settings);

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (network.validate.all model).diagnostics);

  codes = settings: codesOf (modelOf settings);

  networksOf = settings: (network.backends.networkd.links { model = modelOf settings; }).networks;

  resolveOf = settings: (network.resolved { model = modelOf settings; }).Resolve;

  iwdOf = settings: network.wireless.iwd { model = modelOf settings; };

  laptop = {
    profile = "laptop";
  };

  # Settings covering the optional parts of the model.
  contractCases = [
    { }
    laptop
    {
      profile = "laptop";
      links.wireless.enable = false;
      links.usb = {
        match = "usb*";
        priority = 30;
        routeMetric = 512;
      };
      dns.provider = "nextdns";
      wireless.ui = true;
    }
    {
      dns = {
        provider = null;
        servers = [ "9.9.9.9#dns.quad9.net" ];
        dnsOverTls = "opportunistic";
        dnssec = true;
        fallback = [ ];
      };
    }
  ];

  tests = {

    # null on a field that is not nullable still means "not set".
    testNullOverrideOnRequiredField = {
      expr = (modelOf { links.wired.routeMetric = null; }).links.wired.routeMetric;
      expected = 1024;
    };

    # Selectors are strings, so a bad name reaches validation.
    testUnknownBackendOption = {
      expr = codes { backend = "nm"; };
      expected = [ "network.backend.unknown" ];
    };

    testOverlayDefaultsMatchFeature = {
      expr = network.overlays.tailscale { model = modelOf { overlay.enable = true; }; };
      expected = {
        interfaceName = "tailscale0";
        useRoutingFeatures = "client";
        extraUpFlags = [ "--advertise-tags=tag:server" ];
        secret = "tailscale-authkey";
        state.directories = [ "/var/lib/tailscale" ];
      };
    };

    testOverlayFlags = {
      expr =
        (network.overlays.tailscale {
          model = modelOf {
            overlay = {
              enable = true;
              tags = [
                "server"
                "laptop"
              ];
              acceptDns = false;
            };
          };
        }).extraUpFlags;
      expected = [
        "--advertise-tags=tag:server,tag:laptop"
        "--accept-dns=false"
      ];
    };

    testOverlayValidByDefault = {
      expr = map codes [
        { overlay.enable = true; }
        (laptop // { overlay.enable = true; })
      ];
      expected = [
        [ ]
        [ ]
      ];
    };

    testOverlayInterfaceClaimed = {
      expr = codes {
        overlay.enable = true;
        links.all = {
          match = "*";
          routeMetric = 10;
        };
      };
      expected = [ "network.overlay.interface.managed" ];
    };

    testGlobMatching = {
      expr = map (glob: network.query.matchesGlob glob "tailscale0") [
        "*"
        "en*"
        "tail?cale0"
        "tailscale[0-9]"
        "tailscale0.x"
      ];
      expected = [
        true
        false
        true
        true
        false
      ];
    };

    testOverlayTagPrefix = {
      expr = codes {
        overlay = {
          enable = true;
          tags = [ "tag:server" ];
        };
      };
      expected = [ "network.overlay.tag.invalid" ];
    };

    testDisabledOverlayIsNotChecked = {
      expr = codes {
        links.all = {
          match = "*";
          routeMetric = 10;
        };
        overlay.tags = [ "tag:x" ];
      };
      expected = [ ];
    };

    testDefaultLinks = {
      expr = lib.attrNames (modelOf { }).links;
      expected = [ "wired" ];
    };

    testLaptopLinks = {
      expr = lib.mapAttrs (_: link: {
        inherit (link) kind match routeMetric;
      }) (modelOf laptop).links;
      expected = {
        wired = {
          kind = "wired";
          match = "en*";
          routeMetric = 1024;
        };
        wireless = {
          kind = "wireless";
          match = "wl*";
          routeMetric = 2048;
        };
      };
    };

    testOverrideReplacesOnlySetFields = {
      expr =
        let
          link = (modelOf (laptop // { links.wireless.routeMetric = 512; })).links.wireless;
        in
        {
          inherit (link) match routeMetric;
        };
      expected = {
        match = "wl*";
        routeMetric = 512;
      };
    };

    testOverrideAddsLink = {
      expr = (modelOf { links.usb.match = "usb*"; }).links.usb;
      expected = {
        id = "usb";
        kind = "wired";
        match = "usb*";
        priority = 50;
        dhcp = "yes";
        routeMetric = 1024;
        useDhcpDns = false;
        enable = true;
      };
    };

    testUnknownProfile = {
      expr = {
        known = (modelOf { profile = "nope"; }).profile.known;
        codes = codes { profile = "nope"; };
      };
      expected = {
        known = false;
        codes = [
          "network.links.none"
          "network.profile.unknown"
        ];
      };
    };

    testUnsupportedProfileVersion = {
      expr =
        let
          model = modelOf { };
        in
        codesOf (
          model
          // {
            profile = model.profile // {
              version = 2;
            };
          }
        );
      expected = [ "network.profile.version.unsupported" ];
    };

    testEveryProfileIsValid = {
      expr = lib.mapAttrs (
        name: _:
        (network.validate.all (modelOf {
          profile = name;
        })).diagnostics
      ) network.profiles;
      expected = lib.mapAttrs (_: _: [ ]) network.profiles;
    };

    testEveryProviderIsValid = {
      expr = lib.mapAttrs (
        name: _:
        (network.validate.all (modelOf {
          dns.provider = name;
        })).diagnostics
      ) network.providers;
      expected = lib.mapAttrs (_: _: [ ]) network.providers;
    };

    testUnknownProvider = {
      expr = codes { dns.provider = "nope"; };
      expected = [ "network.dns.provider.unknown" ];
    };

    testNoServers = {
      expr = codes { dns.provider = null; };
      expected = [ "network.dns.servers.empty" ];
    };

    testInsecureFallback = {
      expr = codes { dns.fallback = [ "8.8.8.8" ]; };
      expected = [ "network.dns.fallback.insecure" ];
    };

    testServersCarryTlsName = {
      expr = (modelOf { dns.provider = "nextdns"; }).dns.servers;
      expected = map (ip: "${ip}#965e8b.dns.nextdns.io") [
        "45.90.28.0"
        "2a07:a8c0::"
        "45.90.30.0"
        "2a07:a8c1::"
      ];
    };

    testPlainServersWithoutTls = {
      expr = (modelOf { dns.dnsOverTls = "no"; }).dns.servers;
      expected = [
        "1.1.1.1"
        "1.0.0.1"
      ];
    };

    testHostServersTakenAsWritten = {
      expr = (modelOf { dns.servers = [ "9.9.9.9" ]; }).dns.servers;
      expected = [ "9.9.9.9" ];
    };

    testDuplicateMatch = {
      expr = codes (laptop // { links.wireless.match = "en*"; });
      expected = [ "network.link.match.duplicate" ];
    };

    testDuplicateRouteMetric = {
      expr = codes (laptop // { links.wireless.routeMetric = 1024; });
      expected = [ "network.link.routeMetric.duplicate" ];
    };

    testDisabledLinkIsSkipped = {
      expr = {
        codes = codes { links.wired.enable = false; };
        networks = networksOf { links.wired.enable = false; };
      };
      expected = {
        codes = [ "network.links.none" ];
        networks = { };
      };
    };

    # Every model normalize produces satisfies the declared model type.
    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = network.types.model; }; }
                { model = modelOf settings; }
              ];
            }).config.model;
        in
        builtins.deepSeq checked true
      ) contractCases;
      expected = map (_: true) contractCases;
    };

    # The wireless UI only makes sense with a wireless link.
    testWirelessUi = {
      expr = {
        withLink = codes (laptop // { wireless.ui = true; });
        withoutLink = codes {
          profile = "laptop";
          links.wireless.enable = false;
          wireless.ui = true;
        };
        inherit (iwdOf laptop) ui;
      };
      expected = {
        withLink = [ ];
        withoutLink = [ "network.wireless.ui.unused" ];
        ui = "iwgtk";
      };
    };

    testNetworkdUnits = {
      expr = networksOf laptop;
      expected = {
        "20-wired" = {
          name = "en*";
          networkConfig.DHCP = "yes";
          dhcpV4Config = {
            RouteMetric = 1024;
            UseDNS = false;
          };
          ipv6AcceptRAConfig.UseDNS = false;
        };
        "25-wireless" = {
          name = "wl*";
          networkConfig.DHCP = "yes";
          dhcpV4Config = {
            RouteMetric = 2048;
            UseDNS = false;
          };
          ipv6AcceptRAConfig.UseDNS = false;
        };
      };
    };

    testResolvedDefault = {
      expr = resolveOf { };
      expected = {
        DNS = [
          "1.1.1.1#cloudflare-dns.com"
          "1.0.0.1#cloudflare-dns.com"
        ];
        DNSOverTLS = "yes";
        DNSSEC = false;
        FallbackDNS = [ "8.8.8.8#dns.google" ];
      };
    };

    testIwdOnlyWithWireless = {
      expr = {
        wired = (iwdOf { }).active;
        laptop = (iwdOf laptop).active;
        disabled = (iwdOf (laptop // { links.wireless.enable = false; })).active;
      };
      expected = {
        wired = false;
        laptop = true;
        disabled = false;
      };
    };

    testUnknownWirelessBackendOnlyWithWireless = {
      expr =
        let
          withBackend =
            settings:
            let
              model = modelOf settings;
            in
            model
            // {
              wireless = model.wireless // {
                backend = "nope";
              };
            };
        in
        {
          wired = codesOf (withBackend { });
          laptop = codesOf (withBackend laptop);
        };
      expected = {
        wired = [ ];
        laptop = [ "network.wireless.backend.unknown" ];
      };
    };

  };
in
{
  perSystem =
    { pkgs, ... }:
    let
      failures = lib.runTests tests;
    in
    {
      checks.network-unit =
        if failures == [ ] then
          pkgs.runCommand "network-unit-tests" { } "touch $out"
        else
          throw "network unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
