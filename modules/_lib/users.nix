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
      defaultShell ? "bash",
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

            shellMap = {
              inherit (pkgs) bash zsh;
            };
          in
          {
            isNormalUser = true;
            description = fullName;
            extraGroups = finalGroups;
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
