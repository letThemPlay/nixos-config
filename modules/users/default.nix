_: {
  flake.nixosModules.users =
    {
      lib,
      ...
    }:
    {
      imports = [
        ./_kelvin.nix
      ];

      options.users.profiles.enable = lib.mkEnableOption "Global user profile management system" // {
        default = true;
      };
    };
}
