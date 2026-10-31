{ config, ... }:
let
  desktop = config.flake.subsystems.desktop;
in
{
  flake.nixosModules.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        concatMapStringsSep
        escapeShellArg
        filter
        isFunction
        listToAttrs
        mapAttrs
        mapAttrsToList
        mkIf
        mkMerge
        nameValuePair
        ;

      cfg = config.ltp.desktop;

      packageOf = path: lib.getAttrFromPath (lib.splitString "." path) pkgs;

      model = desktop.normalize {
        inherit cfg;
        hasPackage = path: lib.hasAttrByPath (lib.splitString "." path) pkgs;
        keyboard = config.ltp.locale.keyboard.session;
      };

      validation = desktop.validate.all model;

      enabled = map (c: c.name) (filter (c: c.known) model.compositors);

      barModules = model.bar.left ++ model.bar.center ++ model.bar.right;

      #
      # One bar per enabled compositor, each started only in its own
      # session, so several compositors can be offered at login.
      #
      barServices = lib.optionalAttrs (barModules != [ ]) (
        listToAttrs (
          map (
            name:
            nameValuePair "waybar-${name}" {
              description = "Status bar (${name})";
              exec = [
                "${pkgs.waybar}/bin/waybar"
                "-c"
                "%h/.config/waybar/${name}.json"
              ];
              restart = "on-failure";
              compositors = [ name ];
            }
          ) enabled
        )
      );

      inherit
        (desktop.services {
          model = model // {
            services = model.services // barServices;
          };
        })
        units
        ;

      #
      # ExecStart is not a shell, but it accepts single-quoted words;
      # unlike utils.escapeSystemdExecArgs this keeps %h expandable.
      #
      execLine = concatMapStringsSep " " escapeShellArg;

      #
      # How each compositor's system pieces reach NixOS. Every key of
      # desktop.compositors needs an entry here.
      #
      compositorOptions = {
        niri = entry: {
          programs.niri = {
            enable = true;
            package = pkgs.${entry.system.package};
          };
        };
      };

      renderCompositor =
        name: entry:
        mkIf (builtins.elem name enabled) (mkMerge [
          (compositorOptions.${name} entry)

          {
            xdg.portal = {
              enable = true;
              extraPortals = map (portal: pkgs.${portal}) entry.system.portals;
            };

            security.pam.services.login.enableGnomeKeyring = mkIf entry.system.keyring true;

            home-manager.sharedModules = [
              {
                xdg.configFile = {
                  ${entry.configFile}.text = entry.render {
                    inherit model;
                    inherit (desktop) spawnPrefix;
                  };

                  "waybar/${name}.json" = mkIf (barModules != [ ]) {
                    text = builtins.toJSON (
                      desktop.waybar {
                        inherit model;
                        compositor = entry;
                      }
                    );
                  };
                };
              }
            ];
          }
        ]);

      format = diagnostic: "ltp.desktop [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      config = mkMerge [

        # Published on every host, like the other subsystems' facts.
        { ltp.desktop.facts.apps = model.apps; }

        (mkIf cfg.enable (mkMerge [

          {
            assertions = errors;

            warnings = map format validation.warnings;
          }

          #
          # Rendering only runs on a valid model; invalid models stop at
          # the assertions above with a readable diagnostic.
          #
          (mkIf validation.ok (
            mkMerge (
              [
                {
                  # Sessions are started through uwsm (see greetd).
                  environment.systemPackages = [ pkgs.uwsm ];

                  services.dbus.enable = true;

                  home-manager.sharedModules = [
                    {
                      home.packages = map (app: packageOf app.package) (builtins.attrValues model.apps);
                    }

                    (
                      { config, osConfig, ... }:
                      {
                        systemd.user.services = mapAttrs (_: unit: {
                          inherit (unit) Unit Install;

                          Service = unit.Service // {
                            ExecStart = execLine (
                              if isFunction unit.exec then unit.exec { inherit config osConfig; } else unit.exec
                            );
                          };
                        }) units;
                      }
                    )
                  ];
                }
              ]

              ++ mapAttrsToList renderCompositor desktop.compositors
            )
          ))

        ]))

      ];
    };
}
