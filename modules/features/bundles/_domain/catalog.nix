#
# The bundle catalogue: what each bundle turns on, for the README and
# error messages, and the bundles it builds on. requires is resolved
# transitively, so a host lists only the bundles it means. The settings
# are in _configure/<name>.nix.
#
_: {

  base = {
    description = "Every host's defaults: unfree packages allowed, curl, eza, zoxide and nix-ld.";
  };

  window-management = {
    description = "The desktop: niri, the greeter, the bar and the other desktop components, and the users' standard home folders.";
  };

  unified-ui = {
    description = "The unified shell on top of window-management: one themed top bar with a dynamic center island, launcher, notification center, power menu, lock screen, clipboard picker, polkit prompt, level display, quick settings, a calendar, Wi-Fi and Bluetooth panels, battery alerts, display profiles, automounting, screen recording, a night light, a tunnel switcher and a dock. Replaces waybar and its dock, fuzzel, mako, hyprlock and the dmenu clipboard.";
    requires = [ "window-management" ];
  };

  file-handling = {
    description = "Files and links open in the right app: viewers for images (imv), PDFs (zathura) and media (mpv), with the roles in use as the default apps.";
  };

  power = {
    description = "Power profiles (power-profiles-daemon), and battery levels with a clean shutdown as the last resort (UPower).";
  };

  laptop = {
    description = "Audio, bluetooth, a backlight, the wireless UI (iwgtk) and discord.";
  };

  vm = {
    description = "A QEMU/KVM guest (guest agent, SPICE, virtio, serial console) and audio.";
  };

  core-apps = {
    description = "git, with the users' identity, signing and the git aliases.";
  };

  gaming = {
    description = "Steam, GameMode and gamescope.";
  };

  flashgbx = {
    description = "FlashGBX, and serial access for users who list the flashgbx bundle.";
  };

  gpg = {
    description = "The users' OpenPGP keys: gpg-agent with pinentry, SSH through the agent, smartcard rules and git signing.";
  };

  tailscale = {
    description = "Joins the tailnet at boot (the tunnel `tailnet`); the daemon's tags, routes and auth key secret are ltp.network.tailscale options, and exit-node tunnels are host settings.";
  };

}
