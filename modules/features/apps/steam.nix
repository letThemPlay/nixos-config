_: {
  flake.nixosModules.steam-gaming = { pkgs, ... }: {
    nixpkgs.config.allowUnfree = true;

    programs.steam = {
      enable = true;

      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;

      extraPackages = [
        pkgs.protonup-qt
        pkgs.mangohud
      ];
    };

    programs.gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode Active' 'System performance metrics optimized.'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode Ended' 'System returned to standard power profile.'";
        };
      };
    };

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
      PROTON_ENABLE_WAYLAND = "1";
    };

    environment.systemPackages = [
      pkgs.gamescope
    ];
  };
}
