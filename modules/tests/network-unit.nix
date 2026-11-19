{ config, lib, ... }:
let
  network = config.ltp.features.network;

  inherit (config.flake.nixosModules) network-options;

  #
  # Host settings are evaluated through the real options module so option
  # defaults apply exactly as they do on a host.
  #
  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        network-options
        { ltp.network = settings; }
      ];
    }).config.ltp.network;

  modelOf = settings: network.normalize (evalCfg settings);

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (network.validate.all model).diagnostics);

  codes = settings: codesOf (modelOf settings);

  networksOf = settings: (network.backends.networkd.links { model = modelOf settings; }).networks;

  resolveOf = settings: (network.resolved { model = modelOf settings; }).Resolve;

  iwdOf = settings: network.wireless.iwd { model = modelOf settings; };

  secretPath = name: "/run/agenix/${name}";

  tailscaleOf =
    settings:
    network.tunnels.tailscale {
      model = modelOf settings;
      inherit secretPath;
    };

  wireguardOf =
    settings:
    network.tunnels.wireguard {
      model = modelOf settings;
      inherit secretPath;
    };

  laptop = {
    profile = "laptop";
  };

  # A wireguard full tunnel and a split one.
  vpn = {
    backend = "wireguard";
    wireguard = {
      addresses = [ "10.2.0.2/32" ];
      dns = [ "10.2.0.1" ];
      peers.server = {
        publicKey = "server-key";
        endpoint = "vpn.example.org:51820";
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        presharedKey.secret = "vpn-psk";
        persistentKeepalive = 25;
      };
    };
  };

  office = {
    backend = "wireguard";
    wireguard = {
      addresses = [ "10.9.0.5/24" ];
      mtu = 1380;
      peers.gateway = {
        publicKey = "gateway-key";
        endpoint = "office.example.org:51820";
        allowedIPs = [ "10.9.0.0/24" ];
      };
    };
  };

  tailnet = {
    backend = "tailscale";
    autostart = true;
  };

  # The tailnet, and a second mode of it through an exit node.
  twoTailscale.tunnels = {
    inherit tailnet;
    home = {
      backend = "tailscale";
      tailscale.exitNode = "home-server";
    };
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
    (
      twoTailscale
      // {
        tailscale = {
          tags = [ "laptop" ];
          acceptRoutes = true;
        };
      }
    )
    {
      tunnels = {
        inherit vpn office;
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

    testTailscaleAdapterDefaults = {
      expr =
        let
          adapter = tailscaleOf { tunnels.tailnet = tailnet; };
        in
        {
          inherit (adapter)
            active
            daemon
            secrets
            packages
            state
            commands
            ;
        };
      expected = {
        active = true;
        daemon = {
          interfaceName = "tailscale0";
          useRoutingFeatures = "client";
        };
        secrets.tailscale-authkey = { };
        packages = [ "tailscale" ];
        state.directories = [ "/var/lib/tailscale" ];
        commands.tailnet = {
          start = [
            "tailscale"
            "up"
            "--reset"
            "--auth-key=file:/run/agenix/tailscale-authkey"
            "--accept-dns=true"
            "--accept-routes=false"
          ];
          stop = [
            "tailscale"
            "down"
          ];
        };
      };
    };

    testTailscaleFlags = {
      expr =
        (tailscaleOf {
          tailscale = {
            tags = [
              "server"
              "laptop"
            ];
            acceptDns = false;
            acceptRoutes = true;
          };
          tunnels.home = tailnet // {
            tailscale.exitNode = "home-server";
          };
        }).commands.home.start;
      expected = [
        "tailscale"
        "up"
        "--reset"
        "--auth-key=file:/run/agenix/tailscale-authkey"
        "--accept-dns=false"
        "--accept-routes=true"
        "--advertise-tags=tag:server,tag:laptop"
        "--exit-node=home-server"
      ];
    };

    testTailscaleInactiveWithoutTunnels = {
      expr = (tailscaleOf { }).active;
      expected = false;
    };

    # The exit node makes a tailscale tunnel a full tunnel; tailscale
    # tunnels conflict with each other either way.
    testTunnelShape = {
      expr = lib.mapAttrs (_: tunnel: {
        inherit (tunnel)
          interface
          unit
          routesAll
          conflicts
          ;
      }) (modelOf twoTailscale).tunnels;
      expected = {
        home = {
          interface = "tailscale0";
          unit = "ltp-tunnel-home.service";
          routesAll = true;
          conflicts = [ "ltp-tunnel-tailnet.service" ];
        };
        tailnet = {
          interface = "tailscale0";
          unit = "ltp-tunnel-tailnet.service";
          routesAll = false;
          conflicts = [ "ltp-tunnel-home.service" ];
        };
      };
    };

    testDisabledTunnelIsDropped = {
      expr =
        lib.attrNames
          (modelOf {
            tunnels = {
              inherit tailnet;
              off = tailnet // {
                enable = false;
              };
            };
          }).tunnels;
      expected = [ "tailnet" ];
    };

    testTunnelsValidByDefault = {
      expr = map codes [
        { tunnels.tailnet = tailnet; }
        (laptop // twoTailscale)
      ];
      expected = [
        [ ]
        [ ]
      ];
    };

    testUnknownTunnelBackend = {
      expr = codes { tunnels.x.backend = "openvpn"; };
      expected = [ "network.tunnel.backend.unknown" ];
    };

    testTunnelInterfaceClaimed = {
      expr = codes {
        tunnels.tailnet = tailnet;
        links.all = {
          match = "*";
          routeMetric = 10;
        };
      };
      expected = [ "network.tunnel.interface.managed" ];
    };

    testTunnelInterfaceTooLong = {
      expr = codes {
        tailscale.interface = "tailscale-overlay0";
        tunnels.tailnet = tailnet;
      };
      expected = [ "network.tunnel.interface.tooLong" ];
    };

    # What the desktop reads to choose its Wi-Fi panel's backend.
    testWirelessBackendFact = {
      expr = {
        laptop = network.query.wirelessBackend (modelOf laptop);
        wired = network.query.wirelessBackend (modelOf { });
      };
      expected = {
        laptop = "iwd";
        wired = null;
      };
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

    testTailscaleTagPrefix = {
      expr = codes {
        tailscale.tags = [ "tag:server" ];
        tunnels.tailnet = tailnet;
      };
      expected = [ "network.tailscale.tag.invalid" ];
    };

    # The daemon is only checked when a tunnel uses it.
    testUnusedTailscaleIsNotChecked = {
      expr = codes {
        links.all = {
          match = "*";
          routeMetric = 10;
        };
        tailscale.tags = [ "tag:x" ];
      };
      expected = [ ];
    };

    testAutostartConflict = {
      expr = codes {
        tunnels = {
          inherit tailnet;
          home = tailnet // {
            autostart = true;
          };
        };
      };
      expected = [ "network.tunnel.autostart.conflict" ];
    };

    # Full tunnels conflict across backends; a split tunnel with nothing.
    testWireguardShape = {
      expr = lib.mapAttrs (_: tunnel: {
        inherit (tunnel) interface routesAll conflicts;
      }) (modelOf (lib.recursiveUpdate twoTailscale { tunnels = { inherit vpn office; }; })).tunnels;
      expected = {
        home = {
          interface = "tailscale0";
          routesAll = true;
          conflicts = [
            "ltp-tunnel-tailnet.service"
            "ltp-tunnel-vpn.service"
          ];
        };
        office = {
          interface = "wg-office";
          routesAll = false;
          conflicts = [ ];
        };
        tailnet = {
          interface = "tailscale0";
          routesAll = false;
          conflicts = [ "ltp-tunnel-home.service" ];
        };
        vpn = {
          interface = "wg-vpn";
          routesAll = true;
          conflicts = [ "ltp-tunnel-home.service" ];
        };
      };
    };

    testWireguardValid = {
      expr = codes (laptop // { tunnels = { inherit vpn office; }; });
      expected = [ ];
    };

    testWireguardFullTunnel = {
      expr =
        let
          adapter = wireguardOf { tunnels = { inherit vpn; }; };
        in
        {
          netdev = adapter.netdevs."10-vpn";
          network = adapter.networks."10-vpn";
          inherit (adapter) secrets;
          command = adapter.commands.vpn;
        };
      expected = {
        netdev = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg-vpn";
          };
          wireguardConfig = {
            PrivateKeyFile = "/run/agenix/wireguard-vpn";
            RouteTable = 51820;
            FirewallMark = 51820;
          };
          wireguardPeers = [
            {
              PublicKey = "server-key";
              AllowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              Endpoint = "vpn.example.org:51820";
              PresharedKeyFile = "/run/agenix/vpn-psk";
              PersistentKeepalive = 25;
            }
          ];
        };
        network = {
          matchConfig.Name = "wg-vpn";
          address = [ "10.2.0.2/32" ];
          dns = [ "10.2.0.1" ];
          linkConfig = {
            ActivationPolicy = "manual";
            RequiredForOnline = "no";
          };
          domains = [ "~." ];
          networkConfig = {
            DNSOverTLS = "no";
            DNSDefaultRoute = true;
          };
          routingPolicyRules = [
            {
              Table = "main";
              SuppressPrefixLength = 0;
              Priority = 1000;
              Family = "both";
            }
            {
              FirewallMark = 51820;
              InvertRule = true;
              Table = 51820;
              Priority = 1001;
              Family = "both";
            }
          ];
        };
        secrets =
          let
            file = {
              owner = "systemd-network";
              group = "systemd-network";
              mode = "0400";
            };
          in
          {
            wireguard-vpn = file;
            vpn-psk = file;
          };
        command = {
          start = [
            "networkctl"
            "up"
            "wg-vpn"
          ];
          stop = [
            "networkctl"
            "down"
            "wg-vpn"
          ];
          requires = [ "sys-subsystem-net-devices-wg\\x2dvpn.device" ];
        };
      };
    };

    # A split tunnel routes its peers in the main table and leaves the
    # default route and DNS alone.
    testWireguardSplitTunnel = {
      expr =
        let
          adapter = wireguardOf { tunnels = { inherit office; }; };
        in
        {
          inherit (adapter.netdevs."10-office") netdevConfig wireguardConfig;
          network = builtins.attrNames adapter.networks."10-office";
          inherit (adapter.networks."10-office") networkConfig;
        };
      expected = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg-office";
          MTUBytes = "1380";
        };
        wireguardConfig = {
          PrivateKeyFile = "/run/agenix/wireguard-office";
          RouteTable = "main";
        };
        networkConfig = { };
        network = [
          "address"
          "dns"
          "linkConfig"
          "matchConfig"
          "networkConfig"
        ];
      };
    };

    # A split tunnel's resolver answers plain DNS like a full tunnel's, but only
    # for its own domains: no default DNS route.
    testWireguardSplitTunnelDns = {
      expr =
        (wireguardOf {
          tunnels.office = lib.recursiveUpdate office { wireguard.dns = [ "10.9.0.1" ]; };
        }).networks."10-office".networkConfig;
      expected = {
        DNSOverTLS = "no";
      };
    };

    # Beside tailscale, a full tunnel looks in tailscale's table first, so the
    # tailnet stays reachable; a split tunnel adds no rules either way.
    testWireguardTailnetRule = {
      expr =
        let
          adapter = wireguardOf {
            tunnels = {
              inherit tailnet vpn office;
            };
          };
        in
        {
          vpn = builtins.head adapter.networks."10-vpn".routingPolicyRules;
          vpnRules = builtins.length adapter.networks."10-vpn".routingPolicyRules;
          office = adapter.networks."10-office" ? routingPolicyRules;
        };
      expected = {
        vpn = {
          Table = 52;
          SuppressPrefixLength = 0;
          Priority = 900;
          Family = "both";
        };
        vpnRules = 3;
        office = false;
      };
    };

    # Each full tunnel gets its own table and rule priorities.
    testWireguardTables = {
      expr =
        let
          adapter = wireguardOf {
            tunnels = {
              inherit vpn;
              backup = vpn;
            };
          };
        in
        map (name: (map (rule: rule.Priority) adapter.networks.${name}.routingPolicyRules)) [
          "10-backup"
          "10-vpn"
        ];
      expected = [
        [
          1000
          1001
        ]
        [
          1002
          1003
        ]
      ];
    };

    testWireguardErrors = {
      expr = {
        noPeers = codes { tunnels.x.backend = "wireguard"; };
        duplicate = codes {
          tunnels = {
            inherit vpn;
            office = lib.recursiveUpdate office { wireguard.interface = "wg-vpn"; };
          };
        };
        tooLong = codes { tunnels.averyverylongname = office; };
        notNetworkd =
          let
            model = modelOf { tunnels = { inherit office; }; };
          in
          codesOf (model // { backend = "nm"; });
      };
      expected = {
        noPeers = [
          "network.tunnel.wireguard.addresses.none"
          "network.tunnel.wireguard.peers.none"
        ];
        duplicate = [ "network.tunnel.interface.duplicate" ];
        tooLong = [ "network.tunnel.interface.tooLong" ];
        notNetworkd = [
          "network.backend.unknown"
          "network.tunnel.wireguard.backend"
        ];
      };
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
