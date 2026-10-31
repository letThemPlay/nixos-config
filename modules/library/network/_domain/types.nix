{ lib, network }:
let
  inherit (lib) mapAttrs mkOption types;
in
rec {

  # Valid backends are the keys of the registries.
  backend = types.enum (builtins.attrNames network.backends);

  wirelessBackend = types.enum (builtins.attrNames network.wireless);

  dnsOverTLS = types.enum [
    "yes"
    "opportunistic"
    "no"
  ];

  #
  # Link fields, declared once. `link` is the full entity used by
  # profiles and the model; `linkOverride` is the host-facing partial
  # form where null means "not set". normalize merges
  # linkDefaults <- profile link <- override.
  #
  linkFields = {

    kind = {
      type = types.enum [
        "wired"
        "wireless"
      ];

      description = ''
        Medium of this link. Wireless links need a wireless backend.
      '';
    };

    match = {
      type = types.str;

      description = ''
        Interface name glob the link applies to.
      '';
    };

    priority = {
      type = types.ints.between 0 99;

      description = ''
        Ordering prefix of the backend unit; lower sorts first.
      '';
    };

    dhcp = {
      type = types.enum [
        "yes"
        "ipv4"
        "ipv6"
        "no"
      ];

      description = ''
        Which address families are configured by DHCP.
      '';
    };

    routeMetric = {
      type = types.ints.unsigned;

      description = ''
        Metric of routes learned on this link; lower is preferred.
      '';
    };

    useDhcpDns = {
      type = types.bool;

      description = ''
        Whether DNS servers offered by DHCP are used. Off by default
        so lookups always go to the configured DNS provider.
      '';
    };

    enable = {
      type = types.bool;

      description = ''
        Whether this link is configured.
      '';
    };

  };

  # Defaults for a link with the given identifier.
  linkDefaults = _id: {
    kind = "wired";
    match = "*";
    priority = 50;
    dhcp = "yes";
    routeMetric = 1024;
    useDhcpDns = false;
    enable = true;
  };

  link = types.submodule (
    { name, ... }:
    {
      options = {

        id = mkOption {
          type = types.str;
          default = name;

          description = ''
            Canonical identifier for this link.

            Assigned during normalization from the attribute name.
          '';
        };

      }
      // mapAttrs (
        field: spec:
        mkOption {
          inherit (spec) type description;
          default = (linkDefaults name).${field};
        }
      ) linkFields;
    }
  );

  #
  # Host override of a profile link, or a new link. Only fields that
  # are set (non-null) replace the profile value.
  #
  linkOverride = types.submodule {
    options = mapAttrs (
      _: spec:
      mkOption {
        type = types.nullOr spec.type;
        default = null;
        inherit (spec) description;
      }
    ) linkFields;
  };

  profile = types.submodule {
    options = {

      version = mkOption {
        type = types.int;
        default = 1;

        description = ''
          Profile schema version.
        '';
      };

      description = mkOption {
        type = types.lines;

        description = ''
          Human-readable description of this profile.
        '';
      };

      links = mkOption {
        type = types.attrsOf link;
        default = { };

        description = ''
          Links supplied by the profile.
        '';
      };

    };
  };

  provider = types.submodule {
    options = {

      description = mkOption {
        type = types.lines;
      };

      servers = mkOption {
        type = types.listOf types.str;

        description = ''
          Server addresses, without a TLS name.
        '';
      };

      tlsName = mkOption {
        type = types.nullOr types.str;
        default = null;

        description = ''
          Name the servers present for DNS-over-TLS.
        '';
      };

      dnsOverTLS = mkOption {
        type = dnsOverTLS;
        default = "yes";
      };

      fallback = mkOption {
        type = types.listOf types.str;
        default = [ ];

        description = ''
          Servers used when none of the provider's are reachable.
        '';
      };

    };
  };

  model = types.submodule {
    options = {

      profile = mkOption {
        type = types.submodule {
          options = {

            name = mkOption {
              type = types.str;
            };

            known = mkOption {
              type = types.bool;

              description = ''
                Whether the selected profile exists in the profile library.
              '';
            };

            version = mkOption {
              type = types.int;
            };

            description = mkOption {
              type = types.lines;
            };

          };
        };

        description = ''
          Metadata describing the selected network profile.
        '';
      };

      backend = mkOption {
        type = types.str;
      };

      links = mkOption {
        type = types.attrsOf link;

        description = ''
          Fully merged links.
        '';
      };

      wireless = mkOption {
        type = types.submodule {
          options.backend = mkOption {
            type = types.str;
          };
        };
      };

      dns = mkOption {
        type = types.submodule {
          options = {

            provider = mkOption {
              type = types.nullOr types.str;
            };

            known = mkOption {
              type = types.bool;

              description = ''
                Whether the provider exists in the provider registry;
                true when no provider is selected.
              '';
            };

            servers = mkOption {
              type = types.listOf types.str;

              description = ''
                Resolver servers, with `#name` appended when the
                provider has a TLS name.
              '';
            };

            dnsOverTLS = mkOption {
              type = dnsOverTLS;
            };

            dnssec = mkOption {
              type = types.bool;
            };

            fallback = mkOption {
              type = types.listOf types.str;
            };

          };
        };
      };

    };
  };

}
