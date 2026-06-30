_: {
  flake.nixosModules.nextdns = { lib, ... }: {
    options.ltp.network.nextdns.enable =
      lib.mkEnableOption "NextDNS secure encrypted upstream configuration"
      // {
        default = true;
      };
  };
}
