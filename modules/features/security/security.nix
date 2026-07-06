_: {
  flake.nixosModules.security = _: {
    config = {
      security = {
        sudo.enable = false;
        sudo-rs.enable = true;
      };
    };
  };
}
