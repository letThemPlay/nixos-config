{ config, inputs, ... }:
let
  inherit (config.ltp) features;

  inherit (features) bundles;
in
{
  flake.nixosModules.bundles =
    {
      config,
      lib,
      ...
    }:

    let
      inherit (lib)
        mapAttrsToList
        mkIf
        mkMerge
        ;

      cfg = config.ltp.bundles;

      model = bundles.normalize { inherit cfg; };

      validation = bundles.validate.all model;

      #
      # Every bundle's settings, enabled while the bundle is active. A
      # configure file is a module function returning its settings (or
      # { config = settings; }); it also receives inputs and the feature
      # cores. A bundle must not set ltp.bundles, which decides this
      # gate; dependencies go in the catalogue's requires.
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
            config.ltp.bundles.enable && builtins.elem name config.ltp.bundles.facts.active
          ) (configure.config or configure);
        }
      ) bundles.configure;

      format = diagnostic: "ltp.bundles [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      imports = configureModules;

      config = mkMerge [

        # Published on every host, like the other features' facts.
        {
          ltp.bundles.facts = {
            inherit (model) known active;
          };
        }

        (mkIf cfg.enable {
          assertions = errors;

          warnings = map format validation.warnings;
        })

      ];
    };
}
