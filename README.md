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
    persistence.policy.persist.directories = [ "/var/lib/my-service" ];
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

---

## 🧱 Subsystem Conventions

Host-facing configuration lives in subsystems under `modules/subsystems/<name>/` (storage, network, boot, identity, theme, desktop, shell, locale, hardware, nix). Each one follows the same shape and naming.

### Layout

| File | Provides |
|---|---|
| `core.nix` | `flake.subsystems.<name>`: the pure core, assembled from the rings below |
| `_domain/` | entity types and plain data (layouts, profiles, providers, defaults) |
| `_usecases/` | `normalize` (settings → model), `query`, `validate` |
| `_adapters/` | model → plain data for one target (disko, networkd, stylix, …); registries live here |
| `api.nix` | `nixosModules.<name>-api`: options only, under `ltp.<name>` |
| `module.nix` | `nixosModules.<name>`: assertions from validation, then rendering |
| `<target>.nix` | `nixosModules.<name>-<target>` for tool-specific rendering (`identity-home`, `theme-stylix`) |
| `modules/tests/<name>-unit.nix` | `checks.<name>-unit` |

Dependencies point inwards only: `_domain` ← `_usecases` ← `_adapters` ← `api`/`module`. The core never reads NixOS options; `module.nix` passes it plain data, including other subsystems' facts. `modules/subsystems/diagnostics.nix` and `overrides.nix` are shared by every core.

### Options (`ltp.<name>`)

- `enable` on every subsystem (true by default, except storage).
- Read-only results for other modules go under `facts` (`ltp.storage.facts.statePath`, `ltp.identity.facts.users`).
- Collections are attribute sets keyed by name (`volumes`, `links`, `apps`, `binds`, `windowRules`, `gpus`).
- Partial overrides (`storage.volumes`, `network.links`, `desktop.apps`) apply only the fields they define, so a nullable field can be set to `null` on purpose.
- Choosing an implementation: `backend`, a **string** checked against the core's registry. Use a domain noun when the user picks a concept (`boot.loader`, `desktop.compositors`, `hardware.guest`). Never an `enum` of registry keys: a bad name should produce a readable diagnostic listing the known ones.
- "Include the defaults" switches are `default<Things>` (`defaultBinds`, `defaultAliases`, `persistence.defaultPolicy`).
- Acronyms are written as words: `dnsOverTls`, `busId`, `appId`.

### Validation codes

`<subsystem>.<path>.<problem>`, with a plural segment for collection-wide checks (`network.links.none`) and a singular one for items (`network.link.match.duplicate`). `<problem>` is one word:

| Word | Meaning |
|---|---|
| `unknown` | the name is not in a registry or catalogue |
| `unsupported` | a known thing cannot do what is asked |
| `missing` | something required is absent |
| `duplicate`, `multiple`, `ambiguous` | more than one where one is expected |
| `empty`, `none` | an empty value / an empty collection |
| `invalid`, `format`, `order` | malformed or inconsistent values |

### Core attributes

`types`, `normalize`, `query`, `validate`; registries are plural nouns of what they key (`backends`, `loaders`, `compositors`, `gpuVendors`); adapters are named after their target (`preservation`, `resolved`, `systemdUnits`). A core attribute never shares a name with an `ltp.<name>` option of a different meaning.

### Adding a subsystem

1. Create `modules/subsystems/<name>/` with `core.nix`, the rings, `api.nix` and `module.nix`.
2. Add `<name>-api` and `<name>` to the `base` bundle in `modules/features/_registry.nix`.
3. Add `modules/tests/<name>-unit.nix` with a model contract test (normalize output against `types.model`).
4. Features contribute to the subsystem's options; they don't configure its targets directly.
