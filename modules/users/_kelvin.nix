{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.users.profiles.kelvin.enable = lib.mkEnableOption "Kelvin's primary user profile";

  config = lib.mkIf (config.users.profiles.enable && config.users.profiles.kelvin.enable) {
    users.users.kelvin = {
      isNormalUser = true;
      description = "Kelvin";
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "audio"
      ];
      shell = pkgs.zsh;
    };

    #    features.git.userSettings.kelvin = {
    #      fullName = "Kelvin";
    #      email = "kelvin@example.com";
    #    };

    home-manager.users.kelvin = _: {
      home.stateVersion = "26.05";
      home.packages = with pkgs; [
        firefox
        vlc
      ];
    };
  };
}
