#
# git for the system (flakes need it as root) and each user's git
# config: name and email from identity, and commit signing where the
# host sets up gpg and the user has a signing key.
#
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.git ];

  home-manager.sharedModules = [
    (
      {
        config,
        lib,
        osConfig,
        ...
      }:
      let
        userProfile = osConfig.ltp.identity.facts.users.${config.home.username} or { };
      in
      {
        programs.git = {
          enable = true;

          # Signs commits with the user's key where the host sets up gpg.
          signing =
            lib.mkIf (osConfig.ltp.identity.facts.gpg && (userProfile.gpg.signingKey or null) != null)
              {
                key = userProfile.gpg.signingKey;
                format = "openpgp";
                signByDefault = true;
              };

          settings = {
            user = {
              name = userProfile.fullName or "";
              email = userProfile.email or "";
            };
          };
        };
      }
    )
  ];
}
