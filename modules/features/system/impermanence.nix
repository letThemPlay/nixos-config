{ inputs, ... }: {
  flake.nixosModules.state-persistence = _: {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    fileSystems."/persist".neededForBoot = true;

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/ssh"
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/NetworkManager"
        "/etc/secureboot"
        "/var/lib/nixos"
      ];
      files = [
        "/etc/machine-id"
      ];
    };

    home-manager.sharedModules = [

      (_: {
        home.persistence."/persist" = {

          directories = [
            #"Downloads"
            "Music"
            "Pictures"
            "Documents"
            "src"
            ".local/share/niri"
            ".local/share/keyrings"
            ".config/pulse"
            ".mozilla"
            ".config/discord"
          ];
          files = [
            ".zsh_history"
          ];
        };
      })
    ];
  };
}
