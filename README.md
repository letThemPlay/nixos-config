# 🗺️ Guide: Provisioning a New Machine to the Fleet

This guide outlines the deterministic workflow for adding a brand-new bare-metal or virtual machine to your stateless, ephemeral **Dendritic Architecture** utilizing **Btrfs subvolumes**. By leveraging out-of-band pre-evaluation and lazy-loaded registries, provisioning a host requires zero boilerplate.

---

## 🛠️ Step 1: Generate the Core Hardware Profile

Boot your target machine using a standard **NixOS Live Installer USB**. Ensure you have an active network connection, then generate your machine's raw hardware constraints out-of-band:

```zsh
nixos-generate-config --no-filesystems --dir /tmp
```

### ✂️ Clean and Isolate the Hardware Block
Open `/tmp/hardware-configuration.nix`. Because your disk infrastructure is managed cleanly by **Disko**, **remove the entire `fileSystems` and `swapDevices` attribute arrays completely**
 Keep only the raw kernel modules and firmware flags:

```nix
# Example of what to keep: /tmp/hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/hardware/network/links.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_hid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
```

Move this file into your workspace tree under your common hardware paths:
Use code with caution.modules/hosts/_common/hardware-.nix
---

## 💾 Step 2: Configure Storage

Storage is rendered by the `ltp.storage` subsystem (part of the `base` feature). The default `erase-my-darlings` layout creates the disko partitions, Btrfs subvolumes, the initrd rollback of `/` and the preservation rules for system state. `/home` is a persistent subvolume.

Find a stable path for the target drive with `ls -l /dev/disk/by-id` and put the host's storage settings in `modules/hosts/_hosts/_settings/<new-host>.nix`:

```nix
_: {
  ltp.storage = {
    enable = true;

    disk = "/dev/disk/by-id/nvme-Samsung_990_PRO_...";

    # Optional
    encryption.enable = true;
    swap.enable = true;
    swap.size = "16G";

    # Extra state to keep across reboots
    persistence.policy.persist.directories = [ "/var/lib/tailscale" ];
  };
}
```

---

## 📝 Step 3: Populate the Host Datasheet Card

Create your clean, declarative host datasheet profile sheet under **`modules/hosts/_hosts/<new-host>.nix`**. Your file contains **zero hardcoded path blocks** or relative directory walks:

```nix
{ inputs, ... }: {
  hostName = "laptop-x1";
  architecture = "x86_64-linux";
  stateVersion = "26.05";

  features = [
    "base"
    "laptop"
    "window-management"
    "core-apps"
  ];

  users = [ "kelvin" ];

  extraModules = [
    (inputs.self + "/modules/hosts/_hosts/_settings/laptop-x1.nix")
  ];
}
```

---

## 🚀 Step 4: Add the Machine to Root `flake.nix`

Open your root `flake.nix` file and add a public configuration binding line using your central **`mkHost`** factory generator function wrapper:

```nix
nixosConfigurations = {
  vm-test = self.lib.mkHost "vm-test" "x86_64-linux";
  laptop-x1 = self.lib.mkHost "laptop-x1" "x86_64-linux";
};
```

Stash your configuration updates into your index tracker immediately, or the evaluator sandbox will hide the paths from Disko:
```zsh
git add modules/ flake.nix
```

---

## 🔒 Step 5: Execute Remote Partitioning and Installation Passes

From your **NixOS Live Installer terminal window** on the target computer machine, fire off your Disko execution utility script to partition your drive remotely:

```zsh
nix run github:nix-community/disko/latest -- --mode disko --flake "github:Kelvin/my-dendritic-flake#laptop-x1"
```

Once Disko confirms your storage datasets are structured and cleanly mounted under `/mnt`, create a password hash for every user. `/etc` is wiped on every boot, so passwords are declarative and read from the persist volume (agenix cannot be used here: it decrypts after userborn creates the users):

```zsh
mkdir -p /mnt/persist/secrets/passwords
mkpasswd -m yescrypt > /mnt/persist/secrets/passwords/kelvin
chmod 0400 /mnt/persist/secrets/passwords/kelvin
```

Then trigger your core stateless system compilation install pass:

```zsh
# 🚀 2. INSTALL DEPLOYMENT RUN:
sudo nixos-install --flake "github:Kelvin/my-dendritic-flake#laptop-x1"
```

Reboot your machine when complete. Your early-boot Stage 1 systemd unit service will intercept the boot process, flash-wiping your operating system root subvolume clean back to an absolute blank snapshot canvas on every power cycle 
