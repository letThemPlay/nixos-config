{ inputs, findFilesWithExt, ... }: {
  flake.nixosModules.nix-core =
    { pkgs, ... }:
    let
      schemaFiles = findFilesWithExt "nix" "${inputs.self}/modules/_schemas";
    in
    {
      imports = schemaFiles;

      config = {

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
