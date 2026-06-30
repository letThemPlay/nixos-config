_: {
  flake.nixosModules.flashgbx =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.features.flashgbx.enable = lib.mkEnableOption "Software for flashing GBX Carts";

      config = lib.mkIf config.features.flashgbx.enable {

        users.users =
          let
            flashgbxUsers = lib.filterAttrs (
              _: profile: lib.elem "flashgbx" profile.features
            ) config.ltp.users.registry;
          in
          lib.mapAttrs (_: _: {
            extraGroups = [ "dialout" ];
          }) flashgbxUsers;

        environment.systemPackages = [ pkgs.flashgbx ];
      };
    };
}
