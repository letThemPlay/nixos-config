{ lib }: {
  mkUser =
    {
      username,
      fullName,
      email,
      admin ? false,
      features ? [ ],
      extraGroups ? [ "networkmanager" ],
      extraPackages ? [ ],
      ...
    }:
    { config, pkgs, ... }: {
      options.users.profiles.${username}.enable = lib.mkEnableOption "${username}'s user profile";

      config = lib.mkIf (config.users.profiles.enable && config.users.profiles.${username}.enable) {
        users.users.${username} =
          let
            baseGroups = [
              "video"
              "audio"
            ];
            adminGroups = if admin then [ "wheel" ] else [ ];
            finalGroups = baseGroups ++ extraGroups ++ adminGroups;
          in
          {
            isNormalUser = true;
            description = fullName;
            extraGroups = finalGroups;
            shell = pkgs.zsh;
          };

        ltp.users.registry.${username} = {
          inherit
            username
            fullName
            email
            features
            ;
        };

        home-manager.users.${username} = _: {
          home.stateVersion = "26.05";

          home.packages = map (p: pkgs.${p}) extraPackages;
        };
      };
    };
}
