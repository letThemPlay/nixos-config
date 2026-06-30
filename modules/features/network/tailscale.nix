{ inputs, ... }: {
  flake.nixosModules.tailscale =
    { config, lib, ... }:
    let
      cfg = config.ltp.network.tailscale;
      inherit (inputs) self;
    in
    {
      options.ltp.network.tailscale.enable = lib.mkEnableOption "Tailscale Mesh VPN engine" // {
        default = false;
      };

      options.ltp.network.tailscale.interfaceName = lib.mkOption {
        type = lib.types.str;
        default = "tailscale0";
        description = "The virtual network interface target for the Tailscale mesh daemon.";
      };

      config = lib.mkIf cfg.enable {
        services.tailscale = {
          enable = true;
          inherit (cfg) interfaceName;
          useRoutingFeatures = "client";

          authKeyFile = config.age.secrets.tailscale-authkey.path;
          extraUpFlags = [ "--advertise-tags=tag:server" ];
        };

        age.secrets.tailscale-authkey = {
          file = "${self}/secrets/tailscale-authkey.age";
          mode = "0400";
          owner = "root";
        };
      };
    };
}
