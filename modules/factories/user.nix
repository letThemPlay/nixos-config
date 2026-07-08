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
        users.users.${username} = {
          isNormalUser = true;
          description = fullName;

          # Native list concatenation cleanly replaces lib.mkMerge here
          extraGroups = [
            "video"
            "audio"
          ]
          ++ extraGroups
          ++ lib.optionals admin [ "wheel" ];

          shell = pkgs.${defaultShell} or pkgs.bash;
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

        home-manager.users.${username} = {
          home = {
            inherit username;
            stateVersion = config.system.stateVersion or "26.05";

            packages = map (p: pkgs.${p}) extraPackages;
          };
        };
      };
    };
}
