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
      nextdns = [ inputs.self.nixosModules.nextdns ];
      controld-dns = [ inputs.self.nixosModules.controld ];
      nvidia = [ inputs.self.nixosModules.nvidia-graphics ];
      gaming = [ inputs.self.nixosModules.steam-gaming ];
      impermanence = [ inputs.self.nixosModules.state-persistence ];

      base = [
        inputs.self.nixosModules.cachix-caches
        inputs.self.nixosModules.boot
        inputs.self.nixosModules.nix-core
        inputs.self.nixosModules.network
        inputs.self.nixosModules.security
        inputs.self.nixosModules.users
        inputs.self.nixosModules.stylix
        inputs.self.nixosModules.secrets
        inputs.self.nixosModules.zsh
        inputs.self.nixosModules.shell-utilities
      ];

      laptop = [
        inputs.self.nixosModules.discord
        inputs.self.nixosModules.wifi
        inputs.self.nixosModules.bluetooth
        inputs.self.nixosModules.audio
      ];

      vm = [
        inputs.self.nixosModules.proxmox-qemu
        inputs.self.nixosModules.wired
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
