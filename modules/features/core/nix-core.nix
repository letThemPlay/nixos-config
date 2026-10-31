{ inputs, findFilesWithExt, ... }: {
  flake.nixosModules.nix-core =
    { config, pkgs, ... }:
    let
      inherit (config.networking) hostName;

      schemaFiles = findFilesWithExt "nix" "${inputs.self}/modules/_schemas";
    in
    {
      imports = schemaFiles;

      config = {

        # Rebuild this host from the flake in the current directory.
        ltp.shell.aliases = {
          nrs = "sudo nixos-rebuild switch --flake .#${hostName}";
          nrb = "sudo nixos-rebuild boot --flake .#${hostName}";
          nfc = "nix flake check";
        };

        fonts.packages = with pkgs; [
          nerd-fonts.symbols-only
          nerd-fonts.jetbrains-mono
        ];

        nix = {
          settings.auto-optimise-store = true;
          package = pkgs.nixVersions.latest;
          extraOptions = "experimental-features = nix-command flakes pipe-operators";
        };

        time.timeZone = "Europe/London";
        i18n.defaultLocale = "en_GB.UTF-8";
        console.keyMap = "uk";
        systemd.network.wait-online.enable = false;
      };
    };
}
