{ config, inputs, ... }:
let
  theme = config.flake.subsystems.theme;
in
{
  #
  # stylix for every themed user. Separate from the theme module so the
  # theme facts are usable without stylix and home-manager.
  #
  flake.nixosModules.theme-stylix =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ltp.theme;

      rendered = theme.stylix {
        model = {
          inherit (cfg) appearance;
          users = cfg.facts.users;
        };
      };

      packageOf = path: lib.getAttrFromPath (lib.splitString "." path) pkgs;

      fontOf = font: {
        package = packageOf font.package;
        inherit (font) name;
      };
    in
    {
      imports = [
        inputs.stylix.nixosModules.stylix
      ];

      config = lib.mkMerge [

        # Themes are per user, through home-manager.
        { stylix.enable = false; }

        #
        # Every user gets the stylix home module, themed or not: features
        # set stylix.targets.* for all users, and a user left without it
        # would turn a theme error into a missing-option crash.
        #
        {
          home-manager.sharedModules = [
            inputs.stylix.homeModules.stylix
          ];
        }

        (lib.mkIf cfg.enable {
          home-manager.users = lib.mapAttrs (_: user: {
            stylix = {
              enable = true;

              inherit (user) polarity image;

              base16Scheme = "${pkgs.base16-schemes}/share/themes/${user.scheme}.yaml";

              fonts = {
                inherit (user.fonts) sizes;

                monospace = fontOf user.fonts.monospace;
                sansSerif = fontOf user.fonts.sansSerif;
              };

              cursor = fontOf user.cursor // {
                inherit (user.cursor) size;
              };
            };
          }) rendered.users;
        })

        #
        # Users with an unknown theme get a placeholder scheme. It only
        # lets evaluation reach the theme.user.unknown assertion, which
        # still fails the build; stylix would otherwise throw first.
        #
        {
          home-manager.users = lib.mapAttrs (_: _: {
            stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/default-dark.yaml";
          }) (lib.filterAttrs (_: user: !user.known) cfg.facts.users);
        }

      ];
    };
}
