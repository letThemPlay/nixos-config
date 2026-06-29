{ inputs, ... }: {
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./_hardware-configurtion.nix

      inputs.self.nixosModules.nix-core
      inputs.self.nixosModules.secrets
      inputs.self.nixosModules.network
      inputs.self.nixosModules.boot
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd

      (_: {
        system.stateVersion = "22.11";
        networking.hostName = "laptop";

        # Enable your features
        ltp = {
          network.tailscale.enable = true;
          boot = {
            tpmUnlock.enable = true;
            secureBoot.enable = true;
          };
        };
      })
    ];
  };
}
