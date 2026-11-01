{ config, ... }:
let
  identity = config.flake.features.identity;
in
{
  #
  # home-manager wiring for the published users. Separate from the
  # identity module so systems without home-manager can use identity.
  #
  flake.nixosModules.identity-home =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      inherit (config.ltp.identity) facts;

      home = identity.home {
        model.users = facts.users;
        inherit (config.system) stateVersion;
      };

      gpg = identity.gpg {
        model.users = facts.users;

        # A GUI pinentry where the desktop feature runs a session.
        graphical = options ? ltp.desktop && config.ltp.desktop.enable;
      };

      #
      # facts.users is published before validation; an unknown package
      # is reported by the identity assertion, not a missing attribute.
      #
      packagesOf = names: map (name: pkgs.${name}) (builtins.filter (name: pkgs ? ${name}) names);
    in
    {
      config = lib.mkIf config.ltp.identity.enable (
        lib.mkMerge [

          {
            home-manager.users = lib.mapAttrs (_: user: {
              home = user.home // {
                packages = packagesOf user.home.packages;
              };
            }) home.users;
          }

          # OpenPGP only on hosts that opt in (ltp.identity.gpg.enable).
          (lib.mkIf facts.gpg {
            home-manager.users = lib.mapAttrs (_: user: {
              programs.gpg = {
                enable = true;
                inherit (user) publicKeys;
              };

              services.gpg-agent = {
                enable = true;
                enableSshSupport = user.ssh;
                pinentry.package = pkgs.${user.pinentry};
              };

              # Point gpg-agent at the terminal ssh runs in, so the
              # pinentry for the card's auth key appears there.
              programs.ssh = lib.mkIf user.ssh {
                enable = true;
                enableDefaultConfig = false;
                settings.gpg-tty.header = ''Match host * exec "gpg-connect-agent UPDATESTARTUPTTY /bye"'';
              };
            }) gpg.users;
          })

        ]
      );
    };
}
