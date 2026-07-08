{ inputs, ... }: {
  flake.nixosModules.state-persistence = _: {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    config = {
      fileSystems."/persist".neededForBoot = true;

      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib/bluetooth"
          "/var/lib/NetworkManager"
          "/etc/secureboot"
          "/var/lib/nixos"
          "/etc/ssh"
          "/var/lib/systemd"
        ];
        files = [
          "/etc/machine-id"
          "/etc/passwd"
          "/etc/shadow"
          "/etc/group"
        ];
      };

      home-manager.backupFileExtension = "hm-bak";

      home-manager.sharedModules = [
        (_: {
          home.persistence."/persist" = {
            directories = [
              "Downloads"
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
  };
}
