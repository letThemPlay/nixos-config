_: {
  flake.nixosModules.clipboard-manager = { pkgs, ... }: {
    home-manager.sharedModules = [
      (_: {
        home.packages = [
          pkgs.cliphist
          pkgs.wl-clipboard
        ];

        services.cliphist = {
          enable = true;
          allowImages = true;
        };

        home = {
          file.".local/bin/cliphist-picker".text = ''
            #!/bin/sh
            # Queries cliphist list logs and pipes the items to Fuzzel.
            # Selecting an item copies it cleanly back to your primary clipboard register! [INDEX: 1.4.1]
            ${pkgs.cliphist}/bin/cliphist list | ${pkgs.fuzzel}/bin/fuzzel --dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
          '';

          file.".local/bin/cliphist-picker".executable = true;
        };
      })
    ];
  };
}
