#
# Host bundles: settings a datasheet's `bundles` list applies. Every
# feature is present on every host; a bundle decides what it does.
#
_: {
  flake.bundles = {

    base = {
      description = "Every host's defaults: eza and zoxide.";
      module.ltp.apps.install = [
        "eza"
        "zoxide"
      ];
    };

    window-management = {
      description = "The desktop: niri, the greeter, the bar and the other desktop components.";
      module.ltp.desktop.enable = true;
    };

    laptop = {
      description = "Audio, bluetooth, the wireless UI (iwgtk) and discord.";
      module.ltp = {
        apps.install = [ "discord" ];
        network.wireless.ui = true;
        hardware = {
          audio.enable = true;
          bluetooth.enable = true;
        };
      };
    };

    vm = {
      description = "A QEMU/KVM guest (guest agent, SPICE, virtio, serial console) and audio.";
      module.ltp.hardware = {
        guest = "qemu";
        audio.enable = true;
      };
    };

    core-apps = {
      description = "git, with the users' identity, signing and the git aliases.";
      module.ltp.apps.install = [ "git" ];
    };

    gaming = {
      description = "Steam, GameMode and gamescope.";
      module.ltp.apps.install = [ "steam" ];
    };

    flashgbx = {
      description = "FlashGBX, and serial access for users who list the flashgbx bundle.";
      module.ltp.apps.install = [ "flashgbx" ];
    };

    gpg = {
      description = "The users' OpenPGP keys: gpg-agent with pinentry, SSH through the agent, smartcard rules and git signing.";
      module.ltp.identity.gpg.enable = true;
    };

    tailscale = {
      description = "Joins the tailscale network; its tags, routing and auth key secret are ltp.network.overlay options.";
      module.ltp.network.overlay.enable = true;
    };

  };
}
