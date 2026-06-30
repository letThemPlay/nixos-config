_: {
  flake.nixosModules.security = { config, lib, ... }: {

    options.ltp.security.core.enable = lib.mkEnableOption "Core system privilege elevation rules" // {
      default = true;
    };

    config = lib.mkIf config.ltp.security.core.enable {
      security = {
        sudo.enable = false;
        sudo-rs.enable = true;
      };
    };
  };
}
