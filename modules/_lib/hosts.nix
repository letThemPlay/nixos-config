{ inputs, lib }: {
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
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = architecture;

      modules = [
        inputs.home-manager.nixosModules.home-manager
      ]
      ++ (builtins.attrValues inputs.self.nixosModules)
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
            nixvim.enable = enabled.nixvim or false;
            hyprland.enable = enabled.hyprland or false;
          };

          ltp = {
            boot = {
              secureBoot.enable = enabled.secureboot or false;
              tpmUnlock.enable = enabled.tpm or false;
            };

            bluetooth.enable = hasBluetooth;
            audio.pipewire.enable = enabled.pipewire or false;

            network = {
              wifi.enable = hasWifi;
              tailscale.enable = enabled.tailscale or false;
              nextdns.enable = enabled.nextdns or false;
            };

            security = {
              core.enable = enabled.security or true; # Enabled by default unless forced false
              gpg.enable = enabled.gpg or false;
              secrets.enable = enabled.secrets or true; # Agenix decryption defaults true
            };
          };

          environment.systemPackages = [ pkgs.curl ];
        })

        (import "${inputs.self}/modules/hosts/_hosts/_hardware/${hostName}.nix")
      ]
      ++ extraModules;
    };
}
