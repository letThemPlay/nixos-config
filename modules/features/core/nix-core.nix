# modules/features/core/nix-core.nix
{ inputs, ... }: {
  flake.nixosModules.nix-core =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      fsLib = import "${inputs.self}/modules/_lib/filesystem.nix" { inherit lib; };

      # 1. Gather structural types
      schemaFiles = fsLib.findFilesWithExt "nix" "${inputs.self}/modules/_schemas";

      # 2. Gather decoupled raw data theme blocks out of the hidden folder
      themeFiles = fsLib.findFilesWithExt "nix" "${inputs.self}/modules/_themes";
    in
    {
      # Mount structural schemas natively
      imports = schemaFiles;

      options.ltp.core.enable = lib.mkEnableOption "Core baseline configurations" // {
        default = true;
      };

      config = lib.mkIf config.ltp.core.enable {

        fonts.packages = with pkgs; [
          nerd-fonts.symbols-only
          nerd-fonts.jetbrains-mono
        ];

        # 👑 THE DEFINITIVE FIX: Discard the path context tracking from the filename
        # string BEFORE it registers as an official key inside the theme catalog map!
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

        # Your universal platform baseline settings continue completely untouched below
        nix = {
          settings.auto-optimise-store = true;
          package = pkgs.nixVersions.latest;
          extraOptions = "experimental-features = nix-command flakes";
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
    };
}
