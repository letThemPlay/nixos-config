{ inputs, ... }: {
  flake.nixosConfigurations.theseus = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./_hardware-configurtion.nix

      inputs.self.nixosModules.nix-core
      inputs.self.nixosModules.security

      inputs.self.nixosModules.secrets
      inputs.self.nixosModules.network
      inputs.self.nixosModules.audio
      inputs.self.nixosModules.bluetooth
      inputs.self.nixosModules.boot
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd

      (_: {
        system.stateVersion = "22.11";
        networking.hostName = "theseus";

        ltp = {
          audio.pipewire.enable = true;
          boot = {
            tpmUnlock.enable = true;
            secureBoot.enable = true;
          };

          bluetooth.enable = true;

          network = {
            tailscale.enable = true;
            wifi.enable = true;
          };
        };
      })
    ];
  };
}
