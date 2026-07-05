{ inputs, ... }: {
  flake.nixosModules.network =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.network;

      inherit (lib)
        types
        mkOption
        ;
    in
    {
      options.features.network = {
        wired = {
          interfaceName = mkOption {
            default = "en*";
            type = types.str;
          };
        };
      };

      imports = [
        (inputs.self.factory.network {
          networkName = "20-wired";
          inherit (cfg.wired) interfaceName;
          routeMetric = 1024;
        })
      ];
    };
}
