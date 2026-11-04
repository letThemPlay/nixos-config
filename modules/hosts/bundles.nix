#
# Host bundles: settings a host's `bundles` list applies. Every
# feature is present on every host; a bundle decides what it does.
#
_: {
  ltp.bundles = {

    base = {
      description = "Every host's defaults: unfree packages allowed, curl, eza, zoxide and nix-ld.";
      module =
        { pkgs, ... }:
        {
          nixpkgs.config.allowUnfreePredicate = _: true;

          environment.systemPackages = [ pkgs.curl ];

          ltp = {
            nix.ld.enable = true;

            apps.install = [
              "eza"
              "zoxide"
            ];
          };
        };
    };

    window-management = {
      description = "The desktop: niri, the greeter, the bar and the other desktop components, and the users' standard home folders.";
      module.ltp = {
        desktop.enable = true;
        identity.userDirs.enable = true;
      };
    };

    unified-ui = {
      description = "The unified shell on top of window-management: one themed top bar, launcher, notification center, power menu, lock screen, clipboard picker, polkit prompt, level display, quick settings, battery alerts, display profiles, automounting and screen recording. Replaces waybar, the dock, fuzzel, mako, hyprlock and the dmenu clipboard.";
      module.ltp = {
        desktop.components = {
          bar = "quickshell";
          launcher = "quickshell";
          notifier = "quickshell";
          locker = "quickshell";
          power = "quickshell";
          polkit = "quickshell";
          osd = "quickshell";
          quicksettings = "quickshell";
          batteryAlerts = "quickshell";
          displays = "kanshi";
          automount = "udiskie";
          recorder = "wf-recorder";
          nightLight = "wlsunset";
          clipboard = "quickshell";
          dock = "quickshell";
        };

        # The shell draws its own launcher, so nothing starts this role.
        apps.roles.launcher = null;
      };
    };

    file-handling = {
      description = "Files and links open in the right app: viewers for images (imv), PDFs (zathura) and media (mpv), with the roles in use as the default apps.";
      module.ltp.apps = {
        defaultHandlers = true;

        roles = {
          imageViewer = "imv";
          pdfViewer = "zathura";
          mediaPlayer = "mpv";
        };
      };
    };

    power = {
      description = "Power profiles (power-profiles-daemon), and battery levels with a clean shutdown as the last resort (UPower).";
      module.ltp.hardware = {
        powerProfiles.enable = true;
        battery.enable = true;
      };
    };

    laptop = {
      description = "Audio, bluetooth, a backlight, the wireless UI (iwgtk) and discord.";
      module.ltp = {
        apps.install = [ "discord" ];
        network.wireless.ui = true;
        hardware = {
          audio.enable = true;
          bluetooth.enable = true;
          backlight.enable = true;
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
