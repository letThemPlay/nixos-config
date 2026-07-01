# 🗺️ Unified NixOS & Home Manager Fleet Configurations

Welcome to the central orchestration repository for our multi-host infrastructure. This configuration leverages an enterprise-grade **Dendritic Architecture** engineered on top of `flake-parts` and `import-tree`. 

The repository enforces **strict isolation between Structural Schemas, Execution Logic, and Static Data Payloads**, achieving true zero-boilerplate scalability with compile-time type safety.

---

## 🏗️ Repository Architecture

Every directory layer is strictly classified by its functional properties. Folders prefixed with a **hidden underscore (`_`)** are intentionally omitted by `import-tree`'s automatic scanner, completely shielding the system framework from circular dependencies and infinite evaluation loops.

```text
your-flake/
├── flake.nix                 # Flake entry-point (Registers inputs and pins)
└── modules/
    ├── _lib/                 # 🛑 Hidden: Pure functional execution logic (Functions/Lambdas)
    │   ├── filesystem.nix    # Dynamic extension-matching filesystem scraper utility
    │   ├── hosts.nix         # Pinned NixOS platform host template constructor
    │   └── users.nix         # Reusable Home Manager account provisioner engine
    │
    ├── _schemas/             # 🛑 Hidden: Pure structural type layouts (Option blueprints)
    │   ├── hosts.nix         # Fleet configuration constraints (e.g. stylixOverrides)
    │   ├── themes.nix        # Visual palette asset attribute specifications
    │   └── users.nix         # Central persona identity property layout
    │
    ├── _themes/              # 🛑 Hidden: Pure visual theme asset payload sheets
    │   ├── catppuccin.nix    # Raw text properties map for Catppuccin Macchiato
    │   └── tokyonight.nix    # Raw text properties map for Tokyo Night Dark
    │
    ├── features/             # 🟢 Public: Self-registering feature wrapper modules
    │   ├── apps/             # User-facing application layers (git, nixvim, flashgbx)
    │   ├── core/             # Base operating system environment (nix-core)
    │   ├── hardware/         # Device execution targets (audio, bluetooth, boot)
    │   ├── network/          # Networking plumbing components (network, wifi, nextdns, tailscale)
    │   ├── security/         # Cryptographic layers (security, secrets, gpg)
    │   └── wm/               # Desktop window managers and display greeters (hyprland, greetd)
    │
    └── hosts/                # 🟢 Public: Unified physical hardware fleet orchestrator
        ├── default.nix       # Automated machine mapping engine pass
        └── _hosts/           # 🛑 Hidden: Pure JSON-like host definitions
            ├── theseus.nix   # Machine inventory profile asset
            ├── _hardware/    # Isolated disk allocations and local kernel modules
            └── _settings/    # Isolated ergonomic scaling configurations and font metrics
```

---

## 📜 Strict Architectural Design Laws

To ensure the repository passes all pipeline tests completely clean, every module or file added to this flake must comply with the following structural rules:

### 1. Pure Separation of Concerns
* **Data Sheets (`_users/`, `_hosts/`)** must remain entirely declarative data payloads. They must contain zero functional logic, zero code wrappers, and zero nested relative path tracks.
* **Schemas (`_schemas/`)** must contain empty option definition maps (`lib.mkOption`). They are strictly prohibited from initializing configuration default datasets.
* **Features (`features/`)** must be completely self-registering and option-driven. Every public feature file **must** protect its implementations behind a conditional `config = lib.mkIf config.features.<name>.enable` switch to prevent deployment collisions across minimal test hosts.

### 2. Namespace & Classification Boundary Model
Option names must be strictly separated based on whether they modify a standalone application or a global system layer:

| Domain | Target Placement Namespace | Example Practical Syntax |
| :--- | :--- | :--- |
| **Standalone App** | 📦 `features.<app>.enable` | `features.nixvim.enable = true;` |
| **Platform Subsystem** | 👑 `ltp.<domain>.<feature>.enable` | `ltp.security.secrets.enable = true;` |
| **Fleet Metadata** | 👑 `ltp.hosts.registry` | `ltp.hosts.registry.${hostName} = ...;` |
| **Account Identity** | 👑 `ltp.users.registry` | `ltp.users.registry.${userName} = ...;` |

### 3. Absolute Context Purity
* Inside files dynamically scanned during the flake's output compilation phase, you **must not** use `inputs.self` inside lookups or relative path references (`./..`). Doing so forces the compiler into circular file evaluations.
* To pass safe string path strings down to the module system context-free, use **`builtins.toString`** or raw string literals inside local codes, or let the core evaluation layer handle string concatenation at system runtime.

---

## 🛠️ Operational Guide: Scaling the Fleet

Because the gateways are completely automated by our `findFilesWithExt` library helper, expanding your fleet configuration requires absolutely zero changes to the central configuration code.

### How to Add a New User
Create a pure data sheet inside `modules/users/_users/`. Name the file matching the account identity (e.g. `guest.nix`):

```nix
# modules/users/_users/guest.nix
{
  username = "guest";
  fullName = "Restricted Guest Account";
  email = "guest@google.com";
  admin = false;
  features = [ "audio" ];
  extraPackages = [ "chromium" "vlc" ];
  theme = "tokyonight";
}
```
*Run `git add modules/users/_users/guest.nix`. The gateway scraper will discover the account, map its Home Manager parameters, isolate its public keys, and deploy it onto target machines dynamically.*

### How to Add a New Host
Provisioning a new physical machine requires three distinct, self-contained files under `modules/hosts/_hosts/`:

#### 1. Define the Identity Payload (`modules/hosts/_hosts/desktop.nix`)
```nix
# modules/hosts/_hosts/desktop.nix
{ inputs, ... }: {
  hostName = "desktop";
  architecture = "x86_64-linux";
  stateVersion = "26.05";
  isLaptop = false;
  features = [ "git" "nixvim" "stylix" ];
  users = [ "kelvin" "guest" ];
  extraModules = [
    # 👑 Explicit path reference to co-located visuals layout settings module
    "\${inputs.self}/modules/hosts/_hosts/_settings/desktop.nix"
  ];
}
```

#### 2. Define the Ergonomics (`modules/hosts/_hosts/_settings/desktop.nix`)
```nix
# modules/hosts/_hosts/_settings/desktop.nix
{ ... }: {
  # 👑 Isolated visual tuning profiles
  ltp.stylixOverrides = {
    cursorSize = 24; # Pinned for a standard low-DPI screen monitor layout
    fontSize = {
      terminal = 11;
      applications = 12;
      desktop = 10;
    };
  };
}
```

#### 3. Define the Hardware Localizations (`modules/hosts/_hosts/_hardware/desktop.nix`)
```nix
# modules/hosts/_hosts/_hardware/desktop.nix
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (import modulesPath "/installer/scan/not-detected.nix") ];
  boot.initrd.availableKernelModules = [ "nvme" "ahci" "usbhid" ];
  fileSystems."/" = { device = "/dev/disk/by-uuid/your-uuid-here"; fsType = "ext4"; };
}
```

---

## 🚦 Pipeline & Verification Suite

Before pushing any structural edits or adding packages upstream, ensure your local changes pass our mandatory code compliance test suite:

```bash
# 1. Format the codebase and check for dead bindings or unreferenced parameters
deadnix modules/
statix check modules/

# 2. Trigger the Nix compiler evaluation simulation pass
nix flake check
```

Our advanced configuration layers (including **UWSM Session-wrapped Hyprland with hy3 tiling rules** and **Multi-user isolated Stylix theme profiles**) will validate entirely error-free under this strict pipeline framework.

