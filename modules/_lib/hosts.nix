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
      features ? [ ],
      users ? [ ],
      extraModules ? [ ],
      ...
    }:
    let
      enabled = lib.genAttrs features (_: true);

      requestedTokens = [
        "base"
        "laptop"
      ];

      registryData = import (inputs.self + "/modules/features/_registry.nix") {
        inherit inputs;
        lib = inputs.nixpkgs.lib;
      };

      featureRegistryMap = registryData.config.modules.features.registry or { };

      resolvedFeatures = builtins.concatMap (
        name:
        if builtins.hasAttr name featureRegistryMap then
          let
            val = featureRegistryMap.${name};
          in
          if builtins.isList val then
            val
          else if builtins.hasAttr "contents" val then
            val.contents
          else
            [ val ]
        else
          [ ]
      ) requestedTokens;
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = architecture;
      specialArgs = { inherit inputs; };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        (_: {
          nixpkgs.config.allowUnfreePredicate = _: true;
        })
      ]
      ++ resolvedFeatures
      ++ builtins.attrValues (
        removeAttrs inputs.self.nixosModules [
          "discord"
          "wifi"
          "users"
          "stylix"
          "nix-core"
          "security"
          "network"
        ]
      )
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
              features
              users
              extraModules
              ;
          };

          users.profiles = lib.genAttrs users (_: {
            enable = true;
          });

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

            network = {
              nextdns.enable = enabled.nextdns or false;
            };

            security = {
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
