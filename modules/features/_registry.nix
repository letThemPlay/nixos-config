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
      gaming = [ { ltp.apps.install = [ "steam" ]; } ];
      flashgbx = [ { ltp.apps.install = [ "flashgbx" ]; } ];

      base = [
        inputs.self.nixosModules.boot
        inputs.self.nixosModules.boot-api
        inputs.self.nixosModules.nix-api
        inputs.self.nixosModules.nix
        inputs.self.nixosModules.locale-api
        inputs.self.nixosModules.locale
        inputs.self.nixosModules.hardware-api
        inputs.self.nixosModules.hardware
        inputs.self.nixosModules.network
        inputs.self.nixosModules.network-api
        inputs.self.nixosModules.security
        inputs.self.nixosModules.identity-api
        inputs.self.nixosModules.identity
        inputs.self.nixosModules.identity-home
        inputs.self.nixosModules.users
        inputs.self.nixosModules.theme-api
        inputs.self.nixosModules.theme
        inputs.self.nixosModules.theme-stylix
        inputs.self.nixosModules.secrets-api
        inputs.self.nixosModules.secrets
        inputs.self.nixosModules.apps-api
        inputs.self.nixosModules.apps
        inputs.self.nixosModules.shell-api
        inputs.self.nixosModules.shell
        {
          ltp.apps.install = [
            "eza"
            "zoxide"
          ];
        }

        inputs.self.nixosModules.storage
        inputs.self.nixosModules.storage-api
      ];

      laptop = [
        { ltp.apps.install = [ "discord" ]; }
        inputs.self.nixosModules.wifi
        inputs.self.nixosModules.bluetooth
        inputs.self.nixosModules.audio
      ];

      vm = [
        inputs.self.nixosModules.qemu-guest
        inputs.self.nixosModules.audio
      ];

      window-management = [
        inputs.self.nixosModules.desktop-api
        inputs.self.nixosModules.desktop
      ];

      core-apps = [
        { ltp.apps.install = [ "git" ]; }
      ];
    };
  };
}
