{ lib, ... }: {
  config.flake.factory.user =
    {
      username,
      fullName,
      email,
      admin ? false,
      features ? [ ],
      extraGroups ? [ "networkmanager" ],
      extraPackages ? [ ],
      defaultShell ? "bash",
      ...
    }:
    { config, pkgs, ... }: {
      options.users.profiles.${username}.enable = lib.mkEnableOption "${username}'s user profile";

      config = lib.mkIf config.users.profiles.${username}.enable {
        users.users.${username} =
          let
            shellMap = {
              inherit (pkgs) bash zsh;
            };
          in
          {
            isNormalUser = true;
            description = fullName;
            extraGroups = lib.mkMerge [
              extraGroups
              (lib.optionals admin [ "wheel" ])
              [
                "video"
                "audio"
              ]
            ];

            shell = shellMap.${defaultShell} or pkgs.bash;
          };

        ltp.users.registry.${username} = {
          inherit
            username
            fullName
            email
            features
            defaultShell
            ;
        };

        home-manager.users.${username} = _: {
          home.stateVersion = "26.05";

          home.packages = map (p: pkgs.${p}) extraPackages;
        };
      };
    };
}
#_: {
#  config.flake.factory.user =
#    {
#      username,
#      fullName,
#      email,
#      features,
#      isAdmin,
#      extraGroups,
#      extraPackages,
#      defaultShell,
#    }:
#    {
#      config,
#      lib,
#      pkgs,
#    }:
#    {
#      config =
#        let
#          shellMap = {
#            inherit (pkgs) bash zsh;
#          };
#        in
#        lib.mkMerge [
#          {
#            users.users.${username} = {
#              isNormalUser = true;
#              extraGroups = lib.mkMerge [
#                extraGroups
#                (lib.optionals isAdmin [ "wheel" ])
#                [
#                  "video"
#                  "audio"
#                ]
#              ];
#              shell = shellMap.${defaultShell} or pkgs.bash;
#            };
#
#            home-manager.users.${username} = _: {
#              home.stateVersion = "26.05";
#
#              home.packages = map (p: pkgs.${p}) extraPackages;
#            };
#
#            ltp.users.registry.${username} = {
#              inherit
#                username
#                fullName
#                email
#                features
#                defaultShell
#                ;
#            };
#          }
#        ];
#    };
#}
