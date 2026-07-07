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
      cfg = config.registry.hosts.${hostName}.boot or { };

      secureBoot = cfg.secureBoot.enabled or false;
      tpmUnlock = cfg.tpmUnlock.enabled or false;
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
            pkiBundle = "/var/lib/sbctl";
            configurationLimit = 5;
          };
        };
      };
    };
}
