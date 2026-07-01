{ inputs, ... }: {
  flake.nixosModules.stylix =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ltp.theme.stylix;

      themesVault = config.ltp.theme.catalog;
    in
    {
      imports = [
        inputs.stylix.nixosModules.stylix
      ];

      options.ltp.theme.stylix.enable =
        lib.mkEnableOption "Stylix multi-user theme management engine"
        // {
          default = false;
        };

      config = lib.mkIf cfg.enable {
        stylix.enable = false;

        home-manager.users = lib.mapAttrs (_: profile: { ... }: {
          imports = [
            inputs.stylix.homeModules.stylix
          ];

          stylix = {
            enable = true;

            inherit
              (
                let
                  cleanThemeToken = builtins.unsafeDiscardStringContext (profile.theme or "tokyonight");
                in
                themesVault.${cleanThemeToken} or themesVault.tokyonight
              )
              polarity
              ;

            image =
              let
                cleanThemeToken = builtins.unsafeDiscardStringContext (profile.theme or "tokyonight");
                selected = themesVault.${cleanThemeToken} or themesVault.tokyonight;
              in
              "${inputs.self}/modules/features/theme/_theme/${selected.imageName}";

            base16Scheme =
              let
                cleanThemeToken = builtins.unsafeDiscardStringContext (profile.theme or "tokyonight");
                selected = themesVault.${cleanThemeToken} or themesVault.tokyonight;
              in
              "${pkgs.base16-schemes}/share/themes/${selected.schemeName}.yaml";

            fonts = {
              sizes = {
                inherit (config.ltp.stylixOverrides.fontSize)
                  terminal
                  applications
                  desktop
                  ;
              };

              monospace = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font";
              };
              sansSerif = {
                package = pkgs.dejavu_fonts;
                name = "DejaVu Sans";
              };
            };

            cursor = {
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Ice";
              size = config.ltp.stylixOverrides.cursorSize;
            };
          };
        }) config.ltp.users.registry;
      };
    };
}
