{ inputs, ... }: {
  hostName = "vm-test";
  architecture = "x86_64-linux";
  stateVersion = "26.05";
  isLaptop = false;

  features = [
    "wired"
    "proxmox-qemu" # Activates kernel structures, memory trim controllers, and guest agent scripts
    "nixvim"
    "hyprland"
    "greetd"
    "stylix"
    "waybar"
    "fuzzel"
  ];

  users = [ "kelvin" ];

  extraModules = [
    # Reference the cohesive virtual visual adjustments layout module string
    "${inputs.self}/modules/hosts/_hosts/_settings/vm-test.nix"

    #    # 👑 PROXMOX TIP: Use UEFI (OVMF) inside your Proxmox VM settings pane
    #    # If using generic standard GRUB, pass an inline boot module here, or reuse your core boot layer.
    #    ({ ... }: {
    #      boot.loader.systemd-boot.enable = true;
    #      boot.loader.efi.canTouchEfiVariables = true;
    #
    #      # Minimal virtual filesystem mapping block definition
    #      fileSystems."/" = {
    #        device = "/dev/disk/by-label/nixos"; # Match your setup disk installer label format
    #        fsType = "ext4";
    #      };
    #    })
  ];
}
