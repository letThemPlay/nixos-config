_: {
  flake.nixosModules.mako =
    { config, lib, ... }:
    let
      cfg = config.features.mako;
    in
    {
      options.features.mako.enable = lib.mkEnableOption "Mako Wayland notification daemon" // {
        default = false;
      };

      config = lib.mkIf cfg.enable {
        home-manager.sharedModules = [
          ({ config, ... }: {
            xdg.configFile."mako/config".text =
              let
                c = config.lib.stylix.colors;
              in
              ''
                # Compiled Mako Configuration Data Sheet
                layer=overlay
                anchor=top-right
                margin=12,12
                padding=15

                font=JetBrains Mono 10
                default-timeout=5000
                max-icon-size=48

                # 👑 Base16 Skin Injection Matrix
                background-color=#${c.base00}e6 # Added alpha hex opacity tracking
                text-color=#${c.base05}
                border-color=#${c.base0D}
                border-size=2
                border-radius=8
                progress-color=over #${c.base02}

                [urgency=low]
                border-color=#${c.base0B}

                [urgency=high]
                border-color=#${c.base08}
                text-color=#${c.base08}
                default-timeout=0
              '';
          })
        ];
      };
    };
}
