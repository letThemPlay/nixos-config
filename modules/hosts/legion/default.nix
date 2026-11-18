_: {
  # Lenovo Legion laptop: erase-on-boot storage, mounted by label.
  ltp.hosts.legion = {
    system = "x86_64-linux";
    stateVersion = "26.11";

    bundles = [
      "base"
      "laptop"
      "power"
      "file-handling"
      "window-management"
      "unified-ui"
      "core-apps"
      "gaming"
      "gpg"
    ];

    users = [ "kelvin" ];

    module = {
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

        secrets.hostKeyProvisioned = true;

        # IVPN: a full tunnel, switched from the shell. The private key is
        # secrets/wireguard-ivpn.age.
        network.tunnels.ivpn = {
          backend = "wireguard";
          label = "IVPN";

          wireguard = {
            addresses = [
              "172.22.45.43/32"
              "fd00:4956:504e:ffff::ac16:2d2b/128"
            ];
            dns = [ "172.16.0.1" ];

            peers.ivpn = {
              publicKey = "jTRkgALSK2hJZmzfQsyKVsYQEepIqgSDnJImzNyLfQ4=";
              endpoint = "87.249.137.138:2049";
              allowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              persistentKeepalive = 25;
            };
          };
        };

        boot = {
          # Create the keys with `sbctl create-keys` after the first boot.
          secureBoot.enable = false;

          # Enroll once after the install:
          # systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/cryptroot
          tpmUnlock.enable = false;
        };

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
