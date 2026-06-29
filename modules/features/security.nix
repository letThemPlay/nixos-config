_: {
  flake.nixosModules.security = _: {
    security = {
      sudo.enable = false;
      doas.enable = false;
      sudo-rs.enable = true;
    };
  };
}
