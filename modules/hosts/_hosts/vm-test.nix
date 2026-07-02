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
    "mako"
  ];

  users = [ "kelvin" ];

  extraModules = [
    "${inputs.self}/modules/hosts/_hosts/_settings/vm-test.nix"
  ];
}
