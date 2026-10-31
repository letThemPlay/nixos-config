{ config, ... }:
let
  network = config.flake.subsystems.network;
in
{
  #
  # Options only. Merging the profile with host settings is a domain
  # rule and happens in normalize.
  #
  flake.nixosModules.network-api =
    { lib, ... }:
    let
      inherit (lib)
        mkOption
        types
        ;
    in
    {
      options.ltp.network = {

        enable = mkOption {
          type = types.bool;
          default = true;

          description = ''
            Whether the network subsystem configures links and DNS.
          '';
        };

        profile = mkOption {
          type = types.str;
          default = "wired";

          example = "laptop";

          description = ''
            Network profile: the links this kind of host has.
          '';
        };

        backend = mkOption {
          type = types.str;
          default = "networkd";

          description = ''
            Backend that configures the links.
          '';
        };

        wireless.backend = mkOption {
          type = types.str;
          default = "iwd";

          description = ''
            Backend that associates wireless links. Only used when a
            wireless link is enabled.
          '';
        };

        links = mkOption {
          type = types.attrsOf network.types.linkOverride;

          default = { };

          example = {
            wireless.routeMetric = 512;
          };

          description = ''
            Per-host link overrides, merged over the selected profile's
            links. Only fields that are set replace the profile value;
            an attribute that is not in the profile adds a new link.
          '';
        };

        overlay = mkOption {
          type = network.types.overlay;
          default = { };

          example = {
            enable = true;
            tags = [ "laptop" ];
          };

          description = ''
            Mesh VPN overlay (tailscale). The auth key is the agenix
            secret secrets/<authKey.secret>.age, which must be encrypted
            for this host's SSH host key.
          '';
        };

        dns = {

          provider = mkOption {
            type = types.nullOr types.str;
            default = "cloudflare";

            example = "nextdns";

            description = ''
              DNS provider from the provider registry. Null selects no
              provider; dns.servers must then be set.
            '';
          };

          servers = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;

            example = [ "9.9.9.9#dns.quad9.net" ];

            description = ''
              Replaces the provider's servers. Taken as written, so
              append `#name` for DNS-over-TLS verification.
            '';
          };

          dnsOverTls = mkOption {
            type = types.nullOr network.types.dnsOverTls;
            default = null;

            description = ''
              Replaces the provider's DNS-over-TLS mode.
            '';
          };

          dnssec = mkOption {
            type = types.nullOr types.bool;
            default = null;

            description = ''
              Whether DNSSEC is validated. Off when null.
            '';
          };

          fallback = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;

            description = ''
              Replaces the provider's fallback servers.
            '';
          };

        };
      };
    };
}
