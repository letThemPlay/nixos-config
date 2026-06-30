{ inputs, ... }: {
  flake.nixosModules.nix-core = { pkgs, ... }: {
    home-manager.sharedModules = [
      (_: {
        _module.args.lib = inputs.nixpkgs.lib // {
          ltp = inputs.self.lib.ltp;
        };
      })
    ];
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      package = pkgs.nixVersions.latest;
    };

    time.timeZone = "Europe/London";
    i18n.defaultLocale = "en_GB.UTF-8";
    console.keyMap = "uk";

    systemd.network.wait-online.enable = false;

    programs = {
      zsh.enable = true;
      vim = {
        enable = true;
        defaultEditor = true;
      };
    };
  };
}
