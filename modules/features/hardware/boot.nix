{ inputs, ... }: {
  flake.nixosModules.boot =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hostName = config.networking.hostName;
      # Host datasheets set `featureConfig.boot = { secureBoot = true; ... }`.
      cfg = config.registry.hosts.${hostName}.featureConfig.boot or { };

      secureBoot = cfg.secureBoot or false;
      tpmUnlock = cfg.tpmUnlock or false;

      pkiBundle = "/var/lib/sbctl";
    in
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      config = {
        environment.systemPackages =
          lib.optionals tpmUnlock [ pkgs.tpm2-tss ] ++ lib.optionals secureBoot [ pkgs.sbctl ];

        boot = {
          initrd.systemd.enable = true;

          loader = {
            systemd-boot = {
              enable = if secureBoot then lib.mkForce false else true;
              configurationLimit = 5;
            };
            efi.canTouchEfiVariables = !secureBoot;
          };

          lanzaboote = lib.mkIf secureBoot {
            enable = true;
            inherit pkiBundle;
            configurationLimit = 5;
          };
        };

        #
        # Secure Boot keys; losing them leaves the machine unable to sign
        # new generations. Uses this module's own values: reading
        # config.boot.lanzaboote here would loop through the storage
        # module, which consumes persistence.state.
        #
        ltp.storage.persistence.state.directories = lib.mkIf (config.ltp.storage.enable && secureBoot) [
          pkiBundle
        ];
      };
    };
}
