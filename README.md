# NixOS fleet configuration

A NixOS flake for a small fleet of machines, built with [flake-parts](https://flake.parts) and [import-tree](https://github.com/denful/import-tree): every `.nix` file under `modules/` is loaded automatically, except paths starting with `_`.

- **Features** (`modules/features/<name>/`) own all host-facing configuration under `ltp.<name>`: storage, network, boot, identity, theme, desktop, shell, locale, hardware, nix, secrets and apps. Each one validates its settings and reports problems as `ltp.<name> [code]: message`.
- **Bundles** (`ltp.bundles`, defined in `modules/hosts/bundles.nix`) are named sets of feature settings, for example `laptop` or `vm`. Every feature is present on every host; a bundle only decides what it does.
- **Hosts** are flake-parts modules in `modules/hosts/<host>/` defining `ltp.hosts.<host>`: the bundles and users they pick, and their own settings and hardware profile.
- **Users** are flake-parts modules in `modules/users/<name>/` defining `ltp.users.<name>`, enabled per host.

`ltp` names two things. In the flake-parts modules under `modules/`, `ltp.features`, `ltp.bundles`, `ltp.hosts` and `ltp.users` are the fleet's own state, kept off the flake outputs. Inside a host's NixOS configuration, `ltp.<feature>` (`ltp.storage`, `ltp.network`, …) are the feature options.

---

## 📁 Repository layout

```text
modules/
  features/<name>/        one feature: core, options.nix, module.nix and its rings
  hosts/
    bundles.nix           the bundles a host can pick (ltp.bundles)
    <host>/default.nix    a host (ltp.hosts.<host>), with its settings
    <host>/_hardware.nix  its hardware profile
    iso.nix               a minimal installer image
  users/<name>/           a user: default.nix (ltp.users.<name>) and gpg/*.asc keys
  factories/hosts.nix     turns an ltp.hosts entry into a nixosConfiguration
  tests/                  unit tests and the storage VM test (nix flake check)
secrets/                  agenix secrets, their recipients (secrets.nix) and keys (keys.nix)
```

---

## 🧩 Bundles

Bundles are defined in `modules/hosts/bundles.nix` as `ltp.bundles.<name> = { description; module; }`. A bundle holds settings only, and bundles merge, so another file can add to one.

| Bundle | What it turns on |
|---|---|
| `base` | Every host's defaults: unfree packages allowed, curl, eza and zoxide. Every host needs it. |
| `window-management` | The desktop feature: niri, the greeter, the bar and the other desktop components. |
| `laptop` | Audio, bluetooth, the wireless UI (iwgtk) and discord. |
| `vm` | A QEMU/KVM guest (guest agent, SPICE, virtio, serial console) and audio. |
| `core-apps` | git, with the users' identity, signing and the git aliases. |
| `gaming` | Steam, GameMode and gamescope. |
| `flashgbx` | FlashGBX, and serial access for users who list the `flashgbx` bundle. |
| `gpg` | The users' OpenPGP keys: gpg-agent with pinentry, SSH through the agent, smartcard rules and git signing. |
| `tailscale` | Joins the tailscale network. It needs a secret, see [After the first boot](#48-after-the-first-boot). |

---

## 🖥️ Adding a machine

### 4.0 Choose a storage mode

Storage is the one decision to make before installing.

| | A. Erase on boot (default) | B. Persistent root | C. Manual partitioning |
|---|---|---|---|
| Partitioned by | disko, from `ltp.storage` | disko, from `ltp.storage` | you, by hand |
| `/` on reboot | rolled back to an empty snapshot | kept | kept |
| What survives | `/home`, `/nix`, `/persist` and the state preserved into it | everything | everything |
| Btrfs subvolumes, snapshots, LUKS, swap | yes | yes | whatever you create |
| User passwords | hashes in `/persist/secrets/passwords/<user>`, users immutable ([how](#-user-passwords-mode-a)) | `passwd`, users mutable | `passwd`, users mutable |
| Pick it when | you want a clean system on every boot | you want disko's layout without the rollback | you need a layout disko does not cover, or are adopting an existing install |

Mode A is the `erase-my-darlings` layout. It creates the subvolumes `@root`, `@blank`, `@persist`, `@nix`, `@home` and `@snapshots`. On every boot the initrd snapshots `@root` into `@snapshots`, keeping 5 of them, and restores it from `@blank`. [preservation](https://github.com/nix-community/preservation) then bind-mounts system state from `/persist`.

What `/persist` keeps:
- the layout's defaults, such as `/var/log` and systemd state
- what features declare themselves: the SSH host key, iwd networks, tailscale state and Secure Boot keys
- anything you add with `ltp.storage.persistence.policy`

Preservation needs disko. Only the storage feature renders it, so there is no "manual partitioning with preservation".

### 4.1 Boot an installer

Use a NixOS installer ISO, or build this repository's own minimal one, which has git and flakes enabled:

```zsh
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

Boot it on the target, get a network connection, then clone the repository:

```zsh
git clone https://github.com/letThemPlay/nixos-config.git
cd nixos-config
```

All later commands run from this checkout. New files must be `git add`ed before Nix can see them, because flakes only read files git knows about.

### 4.2 Hardware profile

Each host is a folder, `modules/hosts/<host>/`. The hardware profile goes in it as `_hardware.nix`. The leading `_` keeps import-tree from loading it as a flake-parts module, and the host module imports it (4.4).

```zsh
mkdir -p modules/hosts/<host>
```

**Modes A and B.** disko owns the file systems, so leave them out:

```zsh
nixos-generate-config --no-filesystems --show-hardware-config \
  > modules/hosts/<host>/_hardware.nix
```

If the file still declares `fileSystems."/"`, the build fails with a conflicting-definition error naming both files.

**Mode C.** Partition, format and mount the target under `/mnt` yourself first, including `/mnt/boot` for the EFI partition. Then keep the generated file systems:

```zsh
nixos-generate-config --root /mnt --show-hardware-config \
  > modules/hosts/<host>/_hardware.nix
```

Machines with a [nixos-hardware](https://github.com/NixOS/nixos-hardware) profile import it in the host module too, as theseus does with `framework-13-7040-amd`.

### 4.3 Host settings

The host's `ltp.*` settings go in the `module` of its host module (4.4). The examples below show only that part. Pick the disk by a stable path (`ls -l /dev/disk/by-id`); a `/dev/sdX` or `/dev/vdX` name gives a warning.

**Mode A: erase on boot.**

```nix
module.ltp.storage = {
  enable = true;
  disk = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7DNNJ0X000000A";

  # Optional
  encryption.enable = true;   # LUKS; disko asks for the passphrase
  swap = {
    enable = true;            # a swapfile on its own subvolume
    size = "32G";
  };

  # Extra state to keep across reboots, on the persist volume
  persistence.policy.persist.directories = [ "/var/lib/my-service" ];
};
```

**Mode B: persistent root.** These are the mode A settings, plus two lines that turn off the rollback and the layout's preserved state:

```nix
module.ltp.storage = {
  enable = true;
  disk = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7DNNJ0X000000A";

  volumes.root.rollback = false;     # keep / across reboots
  persistence.defaultPolicy = false; # no layout state to preserve
};
```

Features still keep their own few state files, such as the SSH host key and machine-id, on `/persist` and mount them in place. This is harmless with a persistent root.

**Mode C: manual partitioning.** Leave `ltp.storage` out entirely; storage is off by default. The file systems come from the hardware profile.

**Other common settings** (all optional):

```nix
module.ltp = {
  network = {
    profile = "laptop";          # wired (default) or laptop (wired + wireless)
    dns.provider = "controld";   # cloudflare (default), nextdns or controld
  };

  locale = {
    timeZone = "Europe/London";
    keyboard = {
      console = "uk";            # the TTY keymap
      session.layout = "gb";     # the desktop's XKB layout
    };
  };

  hardware.gpus = {
    igpu = { vendor = "amd"; integrated = true; busId = "PCI:6:0:0"; };
    dgpu = { vendor = "nvidia"; busId = "PCI:1:0:0"; };  # PRIME offload by default
  };

  theme.appearance.cursor.size = 32;
};
```

### 4.4 Host module

Create `modules/hosts/<host>/default.nix`. It's a flake-parts module defining `ltp.hosts.<host>`, and every host becomes `nixosConfigurations.<host>`, so `flake.nix` does not change.

```nix
{ inputs, ... }:
{
  ltp.hosts.laptop-x1 = {
    system = "x86_64-linux";
    stateVersion = "26.05";   # the release you install with; never change it later

    bundles = [
      "base"
      "laptop"
      "window-management"
      "core-apps"
    ];

    users = [ "kelvin" ];

    # The host's own NixOS settings: its hardware profile and ltp.* options (4.3)
    module = {
      imports = [
        ./_hardware.nix
        # inputs.nixos-hardware.nixosModules.<profile>
      ];

      ltp.storage = {
        enable = true;
        disk = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7DNNJ0X000000A";
      };
    };
  };
}
```

- **`hostId`:** `networking.hostId` defaults to the first 8 hex digits of the host name's sha256. Set it only to keep an existing machine's ID.
- **Bundles:** an unknown bundle stops the build and lists the known ones. Leave `tailscale`, and anything else that needs a secret, out until after the first boot.
- **Merging:** hosts merge, so another file can add to one, for example `ltp.hosts.laptop-x1.module.ltp.locale.timeZone = "Europe/Paris";`.
- **Shared settings:** settings several hosts share can be an aspect, `flake.modules.nixos.<name>`, imported in each host's `module`. The test VMs share `spice-display` this way (`modules/hosts/spice-display.nix`).

Then make the new files visible to Nix:

```zsh
git add modules/hosts
```

### 4.5 Users

Users already in `modules/users/` only need to be listed in the host'"'"'s `users`. A new user is a folder named after the account, holding a flake-parts module that defines `ltp.users.<name>`:

```nix
# modules/users/alice/default.nix
_: {
  ltp.users.alice = {
    fullName = "Alice";
    email = "alice@example.org";     # used for git
    admin = true;                    # wheel; gets root through sudo-rs
    shell = "zsh";                   # zsh or bash
    theme = "catppuccin";            # catppuccin or tokyonight
    extraPackages = [ "firefox" ];   # package attribute names
    bundles = [ "flashgbx" ];        # applied on hosts that include these bundles

    # Optional OpenPGP; rendered only on hosts with the gpg bundle
    gpg = {
      signingKey = "0x0123456789ABCDEF";
      smartcard = true;
    };

    # Optional home-manager settings for this user only
    home = {
      programs.git.settings.pull.rebase = true;
    };
  };
}
```

- **Field checks:** the identity feature checks every field except `home`, so a misspelt field fails the build.
- **`home`:** a home-manager module applied only on hosts that enable the user.
- **Merging:** users merge, so another file can add to one, for example `ltp.users.alice.home = { … };`.
- **Public keys:** they go in `modules/users/<name>/gpg/*.asc` and are imported with ultimate trust on hosts with the `gpg` bundle.

### 4.6 Format with disko (modes A and B)

Skip this section in mode C; your partitions are already mounted under `/mnt`.

#### Where the disk plan comes from

disko is not configured by hand. The storage feature turns the host's settings into a disko plan:

| Setting | Default | Decides |
|---|---|---|
| `ltp.storage.layout` | `erase-my-darlings` | which volumes exist and which are rolled back |
| `ltp.storage.backend` | `btrfs` | how volumes are rendered (btrfs subvolumes) |
| `ltp.storage.disk` | — | the whole disk that is partitioned |
| `ltp.storage.boot.efiSize` | `1G` | the EFI system partition |
| `ltp.storage.encryption` | off | LUKS around the btrfs partition (`label`, default `cryptroot`) |
| `ltp.storage.swap` | off | a swapfile of `swap.size` on its own subvolume |
| `ltp.storage.filesystem.compression` | `zstd` | btrfs compression for every subvolume except swap |
| `ltp.storage.volumes.<id>` | — | per-volume overrides, e.g. `home.mountpoint = "/data"`; only the fields you set change |

#### What it creates

A GPT partition table on `disk` with two partitions:

| Partition | Size | Content |
|---|---|---|
| `ESP` | `boot.efiSize` | vfat, mounted at `/boot` (`umask=0077`) |
| `root` | the rest | btrfs, or LUKS `cryptroot` holding btrfs |

The btrfs partition holds one subvolume per volume of the layout:

| Subvolume | Mounted at | On every boot |
|---|---|---|
| `@root` | `/` | rolled back from `@blank` (mode A), kept (mode B) |
| `@blank` | not mounted | the empty template `@root` is restored from |
| `@persist` | `/persist` | kept; preserved state is mounted from here |
| `@nix` | `/nix` | kept |
| `@home` | `/home` | kept |
| `@snapshots` | `/.snapshots` | kept; holds the pre-rollback snapshots |
| `@swap` | `/.swapvol` | kept; only with `swap.enable`, uncompressed |

#### Check the plan before erasing anything

Print the partitions and subvolumes disko will create for the host:

```zsh
nix eval .#nixosConfigurations.<host>.config.disko.devices.disk --apply 'd: builtins.mapAttrs (_: disk: {
  inherit (disk) device;
  partitions = builtins.mapAttrs (_: p: {
    inherit (p) size;
    content = p.content.type;
    subvolumes = builtins.mapAttrs (_: v: v.mountpoint or null)
      (p.content.subvolumes or p.content.content.subvolumes or { });
  }) disk.content.partitions;
}) d'
```

Check that `device` is the disk you mean to erase. `nix flake check` also runs the storage checks: an unknown layout (`storage.layout.unknown`), a missing required volume, or a disk name that may change between boots.

#### Run it

Build and run the host's own script. It uses the disko version pinned in `flake.lock`, so it matches what the system will mount:

```zsh
sudo "$(nix build --no-link --print-out-paths \
  .#nixosConfigurations.<host>.config.system.build.destroyFormatMount)/bin/disko-destroy-format-mount"
```

It lists the disks it will wipe and waits for you to type `yes`. With encryption it asks for the LUKS passphrase twice, unless `ltp.storage.encryption.passwordFile` points at a file holding it. The file is only read while formatting.

The disko CLI works too, with the latest disko instead of the pinned one:

```zsh
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake .#<host>
```

#### Check the result

```zsh
findmnt -R /mnt                     # /mnt, /mnt/boot, /mnt/persist, /mnt/nix, /mnt/home, /mnt/.snapshots
sudo btrfs subvolume list /mnt      # @root @blank @persist @nix @home @snapshots (and @swap)
```

To mount an existing install again without formatting, for a rescue or a second `nixos-install`, use the host's mount script:

```zsh
sudo "$(nix build --no-link --print-out-paths \
  .#nixosConfigurations.<host>.config.system.build.mount)/bin/disko-mount"
```

#### The snapshot template (mode A)

There is nothing to snapshot by hand. disko creates `@blank` empty. On every boot, the first one included, the initrd's `storage-rollback` service:

1. saves the current `@root` as a read-only snapshot in `/.snapshots/rollback/root/<timestamp>`, keeping the last 5 (`ltp.storage.rollback.keepSnapshots`);
2. deletes `@root`;
3. creates a new `@root` as a snapshot of `@blank`.

If `@blank` is missing, the service stops without deleting anything.

So, during the install, anything written to `/mnt` outside `/mnt/persist`, `/mnt/home`, `/mnt/nix` and `/mnt/boot` is gone after the first boot. That includes `/etc/shadow`, which is why mode A passwords are files on `/persist` (next section). Anything else to keep goes under `/mnt/persist`, and only the paths in the persistence policy are mounted back into place. If something was lost, the root as `nixos-install` left it is in `/.snapshots/rollback/root/`.

### 4.7 Install

Check the configuration first, then run the steps for your storage mode.

```zsh
nix flake check
```

**Modes A and B.** The disk is formatted and mounted under `/mnt` ([4.6](#46-format-with-disko-modes-a-and-b)). **Mode C:** your own partitions are mounted under `/mnt`.

**Mode A only.** Write each user's password hash to `/mnt/persist/secrets/passwords/<user>` now, as described in [Set the initial password](#set-the-initial-password). `/etc` lives on `@root`, which the first boot erases, so a password set any other way doesn't last.

**All modes.** Install. Root gets no password; admins use `sudo`.

```zsh
sudo nixos-install --flake .#<host> --no-root-passwd
```

**Modes B and C.** Users are mutable, so set each password once:

```zsh
sudo nixos-enter --root /mnt -c 'passwd <user>'
```

Reboot into the new system.

### 4.8 After the first boot

**Register the host for secrets.** agenix decrypts with the SSH host key, which the first boot created and which is preserved in mode A.

1. Add the host's public key to `secrets/keys.nix` under `hosts.<host>`:

   ```zsh
   cat /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Add `keys.hosts.<host>` to the secrets this host needs in `secrets/secrets.nix`, for example `tailscale-authkey.age`.
3. Re-encrypt them:

   ```zsh
   nix develop .#secrets
   cd secrets && agenix -r
   ```

4. Add the bundles that use them, such as `tailscale`, to the host's `bundles`.

A host that uses a secret not encrypted for it fails with `ltp.secrets [secrets.recipient.missing]`, and a host missing from `keys.nix` fails with `secrets.host.unknown`.

**Secure Boot (optional).**

1. Create the keys:

   ```zsh
   sudo sbctl create-keys
   ```

   In mode A they are kept in `/var/lib/sbctl` on `/persist`.
2. Set `ltp.boot.secureBoot.enable = true;` in the host settings and rebuild.
3. Put the firmware into setup mode and enroll the keys:

   ```zsh
   sudo sbctl enroll-keys --microsoft
   ```

**Rebuild.** From the checkout:

```zsh
nrs   # sudo nixos-rebuild switch --flake .#<host>
```

Commit the new host, its settings, its hardware profile and the secrets changes.

### 4.9 When something is wrong

Features check their settings before rendering anything, and fail with a message naming the setting:

```text
ltp.storage [storage.disk.unstable]: Disk '/dev/vda' is not a stable /dev/disk/by-* path.
ltp.identity [identity.user.bundle.unknown]: User 'alice' names unknown bundle 'flashgdx'.
```

Errors stop the build and warnings are printed. `nix flake check` runs every feature's unit tests; `nix build .#vmTests.storage` partitions a VM with disko and boots it.

---

## 🔁 Changing a running machine

- **Rebuild:** `nrs` switches to the checkout's configuration, and `nrb` applies it at the next boot.
- **Turn something on:** add a bundle to the host's `bundles`, or set the feature'"'"'s option in its `module`.
- **Keep extra state in mode A:** add it to `ltp.storage.persistence.policy`. Anything not preserved is gone after the next reboot, and the pre-rollback snapshots in `/.snapshots` are the way back.
- **Before pushing:** run `nix flake check`. It also runs the formatting and lint hooks used on commit.

---

## 🔑 User passwords (mode A)

On an erase-on-boot host `/etc` is rebuilt on every boot, so passwords set with `passwd` don't survive. Each user's password is instead a file on the persist volume.

### How it works

- Each enabled user has one file, `/persist/secrets/passwords/<user>`. It holds a single yescrypt hash, is owned by root and has mode `0400`.
- The identity feature points `users.users.<user>.hashedPasswordFile` at it, and users are immutable (`users.mutableUsers = false`).
- [userborn](https://github.com/nikstur/userborn) creates the accounts early in boot. It reads the hash from the file each time it runs and writes `/etc/shadow` from it. Its database is kept in the preserved `/var/lib/userborn`.
- The files can't be agenix secrets, because agenix decrypts after the users are created.

### Set the initial password

Every user listed in the host'"'"'s `users` needs a hash file **before the first boot**. Without one the user has no password and can't log in, and nothing warns about it at build time.

**When:** during the install, after disko has mounted the disk under `/mnt` ([4.6](#46-format-with-disko-modes-a-and-b)) and before `nixos-install` ([4.7](#47-install)). The persist volume is then mounted at `/mnt/persist`.

**1. Write one hash per user.** `mkpasswd` asks for the password twice and prints only the hash:

```zsh
sudo install -d -m 0700 /mnt/persist/secrets/passwords
for user in kelvin; do            # every user in the host'"'"'s users
  mkpasswd -m yescrypt | sudo tee /mnt/persist/secrets/passwords/$user > /dev/null
  sudo chmod 0400 /mnt/persist/secrets/passwords/$user
done
```

To keep the password off the installer, create the hash on another machine and paste only the hash. Use single quotes, because the hash contains `$`:

```zsh
# on another machine
nix shell nixpkgs#mkpasswd -c mkpasswd -m yescrypt

# on the installer
printf '%s\n' '$y$j9T$…' | sudo tee /mnt/persist/secrets/passwords/kelvin > /dev/null
sudo chmod 0400 /mnt/persist/secrets/passwords/kelvin
```

**2. Check it before installing:**

```zsh
sudo ls -l /mnt/persist/secrets/passwords/        # one file per user, -r-------- root
sudo head -c 3 /mnt/persist/secrets/passwords/kelvin; echo   # prints $y$
```

The files must be under `/mnt/persist`. The first boot erases anything under `/mnt/etc` or elsewhere on `/`, so a `passwd` run inside `nixos-enter` doesn't last.

**3. Install and boot.** Log in with the password at the console or the greeter, then run `sudo -v` to confirm admin rights. Root has no password (`--no-root-passwd`); admins use `sudo`.

If a file was missed, follow [Locked out](#locked-out). For users added after the install, see [Add a user to an existing host](#add-a-user-to-an-existing-host); it's the same file, without the `/mnt` prefix.

### Add a user to an existing host

1. Create the user file ([4.5](#45-users)) and add the user to the host'"'"'s `users` ([4.4](#44-host-module)).
2. Write the hash **before** rebuilding. A user without a file has no password, and nothing warns about it at build time.

   ```zsh
   mkpasswd -m yescrypt | sudo tee /persist/secrets/passwords/<user> > /dev/null
   sudo chmod 0400 /persist/secrets/passwords/<user>
   ```

3. Rebuild with `nrs`.

`mkpasswd` is installed on every host and on the installer.

### Change a password

Write the new hash to the same file, then apply it:

```zsh
mkpasswd -m yescrypt | sudo tee /persist/secrets/passwords/<user> > /dev/null
sudo systemctl restart userborn   # or reboot
```

`nrs` alone does not apply it. userborn restarts when the user configuration changes, not when a hash file does. A change made with `passwd` lasts only until userborn next runs.

### Remove a user

Take the user out of the host'"'"'s `users`, rebuild, then delete `/persist/secrets/passwords/<user>`. Their home in `/home/<user>` stays until you remove it.

### Keep the hashes elsewhere

Set `ltp.identity.passwordDirectory` in the host settings, for example `"/persist/credentials"`. The directory must be on a volume mounted in the initrd (`/persist` is), because userborn runs early in boot.

### Locked out

If a hash file is missing or wrong, nobody can log in as that user:

1. Boot the installer.
2. Mount the host's file systems with its disko mount script ([4.6](#46-format-with-disko-modes-a-and-b)).
3. Write the hash under `/mnt/persist/secrets/passwords/<user>`, mode `0400`.
4. Reboot.

### Modes B and C

Users are mutable there. Set and change passwords with `passwd` as usual.

---

## 🧱 Feature Conventions

Host-facing configuration lives in features under `modules/features/<name>/` (storage, network, boot, identity, theme, desktop, shell, locale, hardware, nix, secrets, apps). Each one follows the same shape and naming.

### Layout

| File | Provides |
|---|---|
| `core.nix` | `ltp.features.<name>`: the pure core, assembled from the rings below |
| `_domain/` | entity types and plain data (layouts, profiles, providers, defaults) |
| `_usecases/` | `normalize` (settings → model), `query`, `validate` |
| `_adapters/` | model → plain data for one target (disko, networkd, stylix, …); registries live here |
| `options.nix` | `nixosModules.<name>-options`: options only, under `ltp.<name>` |
| `module.nix` | `nixosModules.<name>`: assertions from validation, then rendering |
| `<target>.nix` | `nixosModules.<name>-<target>` for tool-specific rendering (`identity-home`, `theme-stylix`) |
| `modules/tests/<name>-unit.nix` | `checks.<name>-unit` |

Dependencies point inwards only: `_domain` ← `_usecases` ← `_adapters` ← `options`/`module`. The core never reads NixOS options; `module.nix` passes it plain data, including other features' facts. `modules/features/diagnostics.nix` and `overrides.nix` are shared by every core.

### Options (`ltp.<name>`)

- `enable` on every feature (true by default, except storage).
- Read-only results for other modules go under `facts` (`ltp.storage.facts.statePath`, `ltp.identity.facts.users`).
- Collections are attribute sets keyed by name (`volumes`, `links`, `apps`, `binds`, `windowRules`, `gpus`).
- Partial overrides (`storage.volumes`, `network.links`, `desktop.apps`) apply only the fields they define, so a nullable field can be set to `null` on purpose.
- Choosing an implementation: `backend`, a **string** checked against the core's registry. Use a domain noun when the user picks a concept (`boot.loader`, `desktop.compositors`, `hardware.guest`). Never an `enum` of registry keys: a bad name should produce a readable diagnostic listing the known ones.
- "Include the defaults" switches are `default<Things>` (`defaultBinds`, `defaultAliases`, `persistence.defaultPolicy`).
- Acronyms are written as words: `dnsOverTls`, `busId`, `appId`.

### Validation codes

`<feature>.<path>.<problem>`, with a plural segment for collection-wide checks (`network.links.none`) and a singular one for items (`network.link.match.duplicate`). `<problem>` is one word:

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

### Adding a feature

1. Create `modules/features/<name>/` with `core.nix`, the rings, `options.nix` and `module.nix`.
2. In its `core.nix`, add `<name>-options` and `<name>` to `flake.modules.nixos.features.imports`, so every host imports it. No bundle changes are needed.
3. Add `modules/tests/<name>-unit.nix` with a model contract test (normalize output against `types.model`).
4. Bundles and other features set the feature's options; they don't configure its targets directly.
