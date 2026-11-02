{ inputs, ... }:
{
  # Framework 13 (AMD 7040) laptop.
  ltp.hosts.theseus = {
    system = "x86_64-linux";
    stateVersion = "22.11";

    bundles = [
      "base"
      "laptop"
      "window-management"
      "core-apps"
      "flashgbx"
      "gpg"
    ];

    users = [ "kelvin" ];

    module = {
      imports = [
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        ./_hardware.nix
      ];

      ltp = {
        network = {
          profile = "laptop";
          dns.provider = "controld";
        };

        boot.secureBoot.enable = true;

        theme.appearance = {
          cursor.size = 32;
          fontSize = {
            terminal = 14;
            applications = 13;
            desktop = 12;
          };
        };
      };
    };
  };
}
