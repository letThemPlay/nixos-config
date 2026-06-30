_: {
  flake.nixosModules.wifi =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      nextDnsActive = config.ltp.network.nextdns.enable or false;

      cfg = config.ltp.network.wifi;
    in
    {
      options.ltp.network.wifi = {
        enable = lib.mkEnableOption "Wi-Fi wireless networking stack" // {
          default = false;
        };
        interfaceName = lib.mkOption {
          type = lib.types.str;
          default = "wl*";
          description = "The target wireless hardware network interface matching string.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.iwgtk ];

        networking.wireless.iwd = {
          enable = true;
          settings = {
            Network = {
              EnableIPv6 = false;
              RoutePriorityOffset = 300;
            };
            Settings = {
              AutoConnect = true;
            };
          };
        };

        systemd.network.networks."25-wireless" = {
          enable = true;
          name = cfg.interfaceName;
          dhcpV4Config.RouteMetric = 2048;
          networkConfig = {
            DHCP = "yes";
            DNSSEC = "no";
            DNSOverTLS = "yes";
            DNS =
              if nextDnsActive then
                [ ]
              else
                [
                  "1.1.1.1"
                  "1.0.0.1"
                ];
          };
        };
      };
    };
}
