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

      schemaFiles = fsLib.findFilesWithExt "nix" "${inputs.self}/modules/_schemas";
    in
    {
      imports = lib.forEach schemaFiles (file: import file { inherit lib; });

      options.ltp.core.enable = lib.mkEnableOption "Core baseline system configurations" // {
        default = true; # Automatically enabled for everything unless forced false
      };

      config = lib.mkIf config.ltp.core.enable {
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
