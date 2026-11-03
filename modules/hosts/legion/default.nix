_: {
  # Lenovo Legion laptop: erase-on-boot storage, mounted by label.
  ltp.hosts.legion = {
    system = "x86_64-linux";
    stateVersion = "26.11";

    bundles = [
      "base"
      "laptop"
      "window-management"
      "core-apps"
      "gaming"
      "gpg"
    ];

    users = [ "kelvin" ];

    module = {
      # TODO: add the model's nixos-hardware profile once known.
      imports = [ ./_hardware.nix ];

      ltp = {
        network.profile = "laptop";

        storage = {
          enable = true;

          # Only read by disko while formatting; the system mounts by label.
          disk = "/dev/nvme0n1";
          labels.enable = true;

          encryption.enable = true;
        };

        boot = {
          # Create the keys with `sbctl create-keys` after the first boot.
          secureBoot.enable = true;

          # Enroll once after the install:
          # systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/cryptroot
          tpmUnlock.enable = true;
        };

        # TODO: the real bus IDs from lspci (hex 01:00.0 is PCI:1:0:0).
        hardware.gpus = {
          igpu = {
            vendor = "amd";
            integrated = true;
            busId = "PCI:6:0:0";
          };
          dgpu = {
            vendor = "nvidia";
            busId = "PCI:1:0:0";
          };
        };
      };
    };
  };
}
