#
# Host bundles: what a datasheet's `bundles` list picks from. Each
# bundle is a list of modules, mostly feature settings; base and
# window-management import the feature modules themselves.
#
{ inputs }:
{
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
    inputs.self.nixosModules.boot-options
    inputs.self.nixosModules.nix-options
    inputs.self.nixosModules.nix
    inputs.self.nixosModules.locale-options
    inputs.self.nixosModules.locale
    inputs.self.nixosModules.hardware-options
    inputs.self.nixosModules.hardware
    inputs.self.nixosModules.network
    inputs.self.nixosModules.network-options
    inputs.self.nixosModules.identity-options
    inputs.self.nixosModules.identity
    inputs.self.nixosModules.identity-home
    inputs.self.nixosModules.users
    inputs.self.nixosModules.theme-options
    inputs.self.nixosModules.theme
    inputs.self.nixosModules.theme-stylix
    inputs.self.nixosModules.secrets-options
    inputs.self.nixosModules.secrets
    inputs.self.nixosModules.apps-options
    inputs.self.nixosModules.apps
    inputs.self.nixosModules.shell-options
    inputs.self.nixosModules.shell
    {
      ltp.apps.install = [
        "eza"
        "zoxide"
      ];
    }

    inputs.self.nixosModules.storage
    inputs.self.nixosModules.storage-options
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
    inputs.self.nixosModules.desktop-options
    inputs.self.nixosModules.desktop
  ];

  core-apps = [
    { ltp.apps.install = [ "git" ]; }
  ];
}
