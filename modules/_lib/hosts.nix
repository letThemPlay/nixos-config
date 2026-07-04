{
  inputs,
  lib,
}:
{
  mkHost =
    {
      hostName,
      architecture,
      stateVersion,
      isLaptop ? false,
      features ? [ ],
      users ? [ ],
      extraModules ? [ ],
    }:
    let
      enabled = lib.genAttrs features (_: true);

      hasWifi = enabled.wifi or false || isLaptop;
      hasBluetooth = enabled.bluetooth or false || isLaptop;
      config.modules.features.activeList = features;
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = architecture;

      modules = [
        inputs.home-manager.nixosModules.home-manager
        (import ./features-gateway.nix { inherit config lib; })
        (_: {
          nixpkgs.config.allowUnfreePredicate = _: true;
        })
      ]
      ++ builtins.attrValues (
        removeAttrs inputs.self.nixosModules [
          "discord"
        ]
      )
      #++ (builtins.attrValues inputs.self.nixosModules)
      ++ [
        ({ pkgs, ... }: {
          system.stateVersion = stateVersion;
          networking.hostName = hostName;
          nixpkgs.hostPlatform = lib.mkDefault architecture;

          ltp.hosts.registry.${hostName} = {
            inherit
              hostName
              architecture
              stateVersion
              isLaptop
              features
              users
              extraModules
              ;
          };

          users.profiles =
            (lib.genAttrs users (_: {
              enable = true;
            }))
            // {
              enable = true;
            };

          features = {
            git.enable = enabled.git or false;
            flashgbx.enable = enabled.flashgbx or false;
            nixvim.enable = enabled.nixvim or false;
            niri.enable = enabled.niri or true; # default to true for now
            fuzzel.enable = enabled.fuzzel or false;
            greetd.enable = enabled.greetd or false;
            waybar.enable = enabled.waybar or false;
            mako.enable = true;
            alacritty.enable = enabled.alacritty or false;
            hardware = {
              proxmox-qemu.enable = enabled.proxmox-qemu or false;
            };
          };

          ltp = {
            boot = {
              secureBoot.enable = enabled.secureboot or false;
              tpmUnlock.enable = enabled.tpm or false;
            };

            bluetooth.enable = hasBluetooth;

            network = {
              wifi.enable = hasWifi;
              wired.enable = !hasWifi || (enabled.wired or false);
              tailscale.enable = enabled.tailscale or false;
              nextdns.enable = enabled.nextdns or false;
            };

            security = {
              core.enable = enabled.security or true; # Enabled by default unless forced false
              gpg.enable = enabled.gpg or false;
              secrets.enable = enabled.secrets or true; # Agenix decryption defaults true
            };

            theme = {
              stylix.enable = enabled.stylix or false;
            };
          };

          environment.systemPackages = [ pkgs.curl ];
        })

        (import "${inputs.self}/modules/hosts/_hosts/_hardware/${hostName}.nix")
      ]
      ++ extraModules;
    };
}
