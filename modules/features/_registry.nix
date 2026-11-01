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
      # Joins the overlay; its tags, routing and auth key secret are
      # ltp.network.overlay options.
      tailscale = [ { ltp.network.overlay.enable = true; } ];

      #
      # Sets up the users' OpenPGP keys: gpg, gpg-agent with pinentry,
      # SSH through the agent, smartcard rules and git signing.
      #
      gpg = [ { ltp.identity.gpg.enable = true; } ];

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
        { ltp.network.wireless.ui = true; }
        {
          ltp.hardware = {
            audio.enable = true;
            bluetooth.enable = true;
          };
        }
      ];

      vm = [
        # A QEMU/KVM guest (e.g. on Proxmox): guest agent, SPICE, virtio
        # initrd modules and a serial console.
        {
          ltp.hardware = {
            guest = "qemu";
            audio.enable = true;
          };
        }
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
