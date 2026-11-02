#
# Host bundles: what a datasheet's `bundles` list picks from. Each
# bundle is a list of feature settings. Every feature is present on
# every host (flake.modules.nixos.features).
#
_: {
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
    {
      ltp.apps.install = [
        "eza"
        "zoxide"
      ];
    }

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
    { ltp.desktop.enable = true; }
  ];

  core-apps = [
    { ltp.apps.install = [ "git" ]; }
  ];
}
