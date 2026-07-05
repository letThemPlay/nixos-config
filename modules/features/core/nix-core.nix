{ inputs, ... }: {
  flake.nixosModules.nix-core =
    {
      lib,
      pkgs,
      ...
    }:
    let
      fsLib = import "${inputs.self}/modules/_lib/filesystem.nix" { inherit lib; };

      schemaFiles = fsLib.findFilesWithExt "nix" "${inputs.self}/modules/_schemas";

      themeFiles = fsLib.findFilesWithExt "nix" "${inputs.self}/modules/_themes";
    in
    {
      imports = schemaFiles;

      config = {

        fonts.packages = with pkgs; [
          nerd-fonts.symbols-only
          nerd-fonts.jetbrains-mono
        ];

        ltp.theme.catalog = lib.listToAttrs (
          lib.forEach themeFiles (
            file:
            let
              rawName = lib.removeSuffix ".nix" (baseNameOf file);
              cleanCatalogKey = builtins.unsafeDiscardStringContext rawName;
            in
            {
              name = cleanCatalogKey;
              value = import file;
            }
          )
        );

        nix = {
          settings.auto-optimise-store = true;
          package = pkgs.nixVersions.latest;
          extraOptions = "experimental-features = nix-command flakes";
        };

        time.timeZone = "Europe/London";
        i18n.defaultLocale = "en_GB.UTF-8";
        console.keyMap = "uk";
        systemd.network.wait-online.enable = false;
      };
    };
}
