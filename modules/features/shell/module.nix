{ config, ... }:
let
  shell = config.ltp.features.shell;
in
{
  flake.nixosModules.shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        filterAttrs
        genAttrs
        mapAttrs
        mapAttrsToList
        mkIf
        mkMerge
        ;

      cfg = config.ltp.shell;

      model = shell.normalize {
        inherit cfg;
        users = config.ltp.identity.facts.users;
      };

      validation = shell.validate.all model;

      # Users with an unknown shell are left out; validation reports them.
      known = filterAttrs (_: user: user.known) model.users;

      #
      # Every registered shell enables its system programs behind
      # mkIf (some user logs in with it), so the module's shape does
      # not depend on config.
      #
      renderSystem =
        name: entry:
        mkIf (builtins.elem name model.shells) {
          programs = genAttrs entry.system.programs (_: {
            enable = true;
          });
        };

      format = diagnostic: "ltp.shell [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      config = mkMerge [

        # Published on every host, like the other features' facts.
        { ltp.shell.facts.users = model.users; }

        (mkIf cfg.enable (
          mkMerge (
            [
              {
                assertions = errors;

                warnings = map format validation.warnings;

                users.users = mapAttrs (_: user: {
                  shell = pkgs.${shell.shells.${user.shell}.package};
                }) known;

                home-manager.users = mapAttrs (
                  _: user:
                  shell.shells.${user.shell}.render {
                    inherit (model) aliases;
                    inherit pkgs;
                  }
                ) known;
              }
            ]

            ++ mapAttrsToList renderSystem shell.shells
          )
        ))

      ];
    };
}
