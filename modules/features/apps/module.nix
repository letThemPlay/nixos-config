{ config, inputs, ... }:
let
  inherit (config.ltp) features;

  inherit (features) apps;
in
{
  flake.nixosModules.apps =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        attrValues
        concatStringsSep
        filter
        mapAttrsToList
        mkIf
        mkMerge
        ;

      cfg = config.ltp.apps;

      packagePath = lib.splitString ".";

      model = apps.normalize {
        inherit cfg;
        hasPackage = path: lib.hasAttrByPath (packagePath path) pkgs;
      };

      validation = apps.validate.all model;

      editor = model.roles.editor or null;

      #
      # Every app's configure module, enabled while the app plays a role
      # or is installed. A configure file is a module function returning
      # its settings (or { config = settings; }); it also receives inputs and the feature cores.
      #
      configureModules = mapAttrsToList (
        name: path:
        {
          config,
          lib,
          pkgs,
          ...
        }@args:
        let
          configure = import path (args // { inherit pkgs inputs features; });
        in
        {
          config = lib.mkIf (
            config.ltp.apps.enable
            && builtins.elem name (attrValues config.ltp.apps.roles ++ config.ltp.apps.install)
          ) (configure.config or configure);
        }
      ) apps.configure;

      format = diagnostic: "ltp.apps [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      imports = configureModules;

      config = mkMerge [

        # Published on every host, like the other features' facts.
        { ltp.apps.facts = model.roles; }

        (mkIf cfg.enable (mkMerge [

          {
            assertions = errors;

            warnings = map format validation.warnings;
          }

          #
          # Rendering only runs on a valid model; invalid models stop at
          # the assertions above with a readable diagnostic.
          #
          (mkIf validation.ok (mkMerge [

            # Role and installed apps for every user (configure modules may
            # add more).
            {
              home-manager.sharedModules = [
                {
                  home.packages = map (app: lib.getAttrFromPath (packagePath app.package) pkgs) (
                    filter (app: app.package != null) (attrValues model.roles ++ attrValues model.installed)
                  );
                }
              ];
            }

            # The aliases of the apps in use, in every shell.
            { ltp.shell.aliases = model.aliases; }

            # The editor: `v` in every shell and each user's EDITOR.
            (mkIf (editor != null) {
              ltp.shell.aliases.v = concatStringsSep " " editor.command;

              home-manager.sharedModules = [
                { home.sessionVariables.EDITOR = concatStringsSep " " editor.command; }
              ];
            })

          ]))

        ]))

      ];
    };
}
