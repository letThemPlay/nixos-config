# CLAUDE.md

A NixOS fleet flake in the dendritic flake-parts pattern, with clean-architecture features. README.md holds the install guide and the full **🧱 Feature Conventions**. This file covers the rules that are easy to break.

## Architecture

- **Every file is a flake-parts module.** `import-tree` loads all of `modules/` except paths starting with `_`. Values flow through flake-parts `config`. Never use `inputs.self`, file paths or `_module.args` to pass them. Shared helpers live in `config.ltp.lib`.
- **There are two `ltp` namespaces.**
  - At the flake level, `ltp.{features,hosts,bundles,users,factory,lib}` is internal state and never a flake output. `flake.*` holds only real outputs.
  - Inside NixOS, `ltp.<feature>` holds that feature's options.
- **Feature layout** (`modules/features/<x>/`):
  - `core.nix`: `ltp.features.<x> = lib.fix (<x>: …)`, assembled from the rings below. It also adds `<x>-options` and `<x>` to `flake.modules.nixos.features`.
  - `_domain/`: types and plain data. `_usecases/`: `normalize`, `validate`, `query`. `_adapters/`: model → plain data for one target.
  - `options.nix`: `nixosModules.<x>-options`. `module.nix`: `nixosModules.<x>`.
  - Dependencies point inwards only. The core is pure functions, reads no NixOS options and uses no `mkIf`.
  - `module.nix` runs normalize, then validate, turns diagnostics into assertions and warnings, and renders only under `mkIf validation.ok`.
  - Other features are read only through `ltp.<x>.facts`.
- **Composition:**
  - Every host imports every feature (`flake.modules.nixos.features`).
  - Bundles (`modules/hosts/bundles.nix`, `ltp.bundles.<name> = { description; module; }`) hold settings only. Host policy goes in a bundle, never in the factory (`modules/hosts/factory.nix`). Settings several hosts share are aspects in `modules/hosts/shared/` (`flake.modules.nixos.<name>`).
  - Hosts live in `modules/hosts/<host>/default.nix` as `ltp.hosts.<host> = { system; stateVersion; hostId; bundles; users; module; }`, with `_hardware.nix` beside it.
  - Users live in `modules/users/<name>/default.nix` as `ltp.users.<name>`. The `home` module holds home-manager settings, and `gpg/*.asc` holds public keys.
- **Choosing an implementation:** a string checked against the core's registry (`backend`, `loader`, `compositors`, …), never an `enum`. Diagnostics read `ltp.<x> [<feature>.<path>.<problem>]: message`.

## Commands

| Command | Purpose |
|---|---|
| `nix flake check` | unit checks, nixfmt, statix, deadnix and `no-rec`; also evaluates every host |
| `nix build .#vmTests.storage` | storage VM test: format, install, three boots (several minutes) |
| `nix eval --raw .#nixosConfigurations.<h>.config.system.build.toplevel.drvPath` | fast "does it evaluate" check |
| `nix eval --json .#nixosConfigurations.<h>.config.warnings` | warnings without a build |
| `nix develop` | dev shell; installs the commit hooks (rerun after changing `modules/development/git-hooks.nix`) |
| `nrs` / `nrb` | `nixos-rebuild switch` / `boot` for the current host |

The hosts are `theseus`, `vm-test` and `vm-test2`, plus `iso`.

## Testing

- **One unit test per feature:** `modules/tests/<x>-unit.nix` uses `lib.runTests` and exposes `checks.<x>-unit`.
  - Settings are evaluated against `<x>-options` alone, with no NixOS.
  - Always include a model contract test: the `normalize` output checked against `types.model`.
  - Error cases check diagnostic codes, not message text.
- **Refactors must leave hosts unchanged:** compare the toplevel `drvPath` for all four hosts before and after. Identical paths mean nothing changed.
- **After `nix flake update`:** evaluate every host and read its warnings. Temporary upstream workarounds must fail loudly once upstream changes, like the `--replace-fail` in `modules/tests/storage-vm.nix`.
- **For scratch experiments** (a second file extending a host, negative checks), use a throwaway `git worktree` and remove it afterwards. New files must be `git add`ed before flake evaluation sees them.

## Style

- **No `rec`.** Use `let … in { inherit …; }`; a core uses `lib.fix` with a named self. The `no-rec` hook enforces this.
- `lib` means nixpkgs `lib` only. Project helpers live in `modules/helpers/` and are exposed as `config.ltp.lib`.
- **Options:**
  - Packages are pkgs attribute-path strings (`"nixVersions.latest"`), resolved and validated in `module.nix`.
  - Collections are attribute sets keyed by name.
  - "Include the defaults" switches are named `default<Things>`.
  - Acronyms are written as words (`dnsOverTls`, `busId`).
  - Every feature has `enable`.
- Format with nixfmt. Statix wants repeated keys merged (`ltp = { a = …; b = …; };`).
- Comments use `#` blocks that explain why.
- **Commits:** `<area>: <summary>`, one logical change each, with the reason in the body. If nixfmt rewrites files during the hook, re-add them and commit again.

## Easy to get wrong

- **Keyboard:** console keymap `uk` and session layout `gb` are separate on purpose.
- **Storage mode A** (ephemeral root): state that must survive a reboot is declared in `ltp.storage.persistence`. Anything else is wiped.
- **Removed NixOS option:** `boot.initrd.systemd.enable` is gone (the systemd initrd is always on). Don't set or read it.
- **Upstream workarounds, to delete when upstream is fixed:**
  - The patched disko test library in `modules/tests/storage-vm.nix`.
  - `ltp.theme.untargeted = [ "rofi" ]` in `modules/features/theme/stylix.nix`.
- **Hardware profile:** `modules/hosts/_unused/legion.nix` is kept on purpose.
- **`hostId`:** existing hosts pin `hostId = "deadbeef"`; new hosts derive it from their name.
- **Pushing:** only on request: `git push origin`.
