{ lib, inputs, ... }: {
  options.modules.features = {
    registry = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.deferredModule);
      default = { };
      description = "Central feature registry map holding merged modules.";
    };
  };

  config = {
    modules.features.registry = {
      tailscale = [ inputs.self.nixosModules.tailscale ];
      gpg = [ inputs.self.nixosModules.gpg ];
      nvidia = [ inputs.self.nixosModules.nvidia-graphics ];
      gaming = [ inputs.self.nixosModules.steam-gaming ];
      flashgbx = [ inputs.self.nixosModules.flashgbx ];

      base = [
        inputs.self.nixosModules.cachix-caches
        inputs.self.nixosModules.boot
        inputs.self.nixosModules.boot-api
        inputs.self.nixosModules.nix-core
        inputs.self.nixosModules.network
        inputs.self.nixosModules.network-api
        inputs.self.nixosModules.security
        inputs.self.nixosModules.identity-api
        inputs.self.nixosModules.identity
        inputs.self.nixosModules.identity-home
        inputs.self.nixosModules.users
        inputs.self.nixosModules.theme-api
        inputs.self.nixosModules.theme
        inputs.self.nixosModules.stylix
        inputs.self.nixosModules.secrets
        inputs.self.nixosModules.zsh
        inputs.self.nixosModules.shell-utilities

        inputs.self.nixosModules.storage
        inputs.self.nixosModules.storage-api
      ];

      laptop = [
        inputs.self.nixosModules.discord
        inputs.self.nixosModules.wifi
        inputs.self.nixosModules.bluetooth
        inputs.self.nixosModules.audio
      ];

      vm = [
        inputs.self.nixosModules.proxmox-qemu
        inputs.self.nixosModules.audio
      ];

      window-management = [
        inputs.self.nixosModules.niri
        inputs.self.nixosModules.waybar
        inputs.self.nixosModules.fuzzel
        inputs.self.nixosModules.mako
        inputs.self.nixosModules.greetd
        inputs.self.nixosModules.hyprlock
        inputs.self.nixosModules.clipboard-manager
        inputs.self.nixosModules.desktop-utilities
      ];

      core-apps = [
        inputs.self.nixosModules.alacritty
        inputs.self.nixosModules.git
        inputs.self.nixosModules.nixvim
      ];
    };
  };
}
