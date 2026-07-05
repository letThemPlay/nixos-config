{ inputs, ... }: {
  flake.nixosModules.wired =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.network.wired;

      inherit (lib)
        types
        mkOption
        ;
    in
    {
      options.features.network = {
        wired = {
          networkName = mkOption {
            default = "20-wired";
          };
          interfaceName = mkOption {
            default = "en*";
            type = types.str;
          };
          routeMetric = mkOption {
            default = 1024;
            type = types.int;
          };
        };
      };

      imports =
        let
          networkcfg = {
            inherit (cfg) networkName interfaceName routeMetric;
          };
        in
        [
          (inputs.self.factory.network networkcfg)
        ];
    };
}
