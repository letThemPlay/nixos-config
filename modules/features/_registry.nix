{ lib, inputs, ... }: {
  options.modules.features = {
    registry = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.deferredModule);
      default = { };
      description = "Central cumulative feature registry map holding merged modules.";
    };
  };

  config = {
    modules.features.registry = {
      # Individual features wrapped in a list to match the type
      tailscale = [ inputs.self.nixosModules.tailscale ];
      gpg = [ inputs.self.nixosModules.gpg ];
      nextdns = [ inputs.self.nixosModules.nextdns ];

      # Feature Groups as clean lists of modules
      base = [
        inputs.self.nixosModules.boot
        inputs.self.nixosModules.nix-core
        inputs.self.nixosModules.network
        inputs.self.nixosModules.security
        inputs.self.nixosModules.users
        inputs.self.nixosModules.stylix
        inputs.self.nixosModules.secrets
        inputs.self.nixosModules.zsh
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

      ui = [
        inputs.self.nixosModules.niri
        inputs.self.nixosModules.waybar
        inputs.self.nixosModules.fuzzel
        inputs.self.nixosModules.mako
        inputs.self.nixosModules.greetd
        inputs.self.nixosModules.hyprlock
      ];

      core-apps = [
        inputs.self.nixosModules.alacritty
        inputs.self.nixosModules.git
        inputs.self.nixosModules.nixvim
      ];
    };
  };
}
