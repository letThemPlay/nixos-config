{ config, ... }:
let
  desktop = config.ltp.features.desktop;
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

      #
      # Every registered component, each enabled only when selected for
      # its role. A component file is a module function returning its
      # settings (or { config = settings; }).
      #
      componentModules = lib.concatLists (
        mapAttrsToList (
          role: implementations:
          mapAttrsToList (
            name: path:
            {
              config,
              lib,
              pkgs,
              ...
            }@args:
            let
              # The module system passes pkgs only to functions naming it.
              component = import path (args // { inherit pkgs; });
            in
            {
              config = lib.mkIf (config.ltp.desktop.enable && config.ltp.desktop.components.${role} == name) (
                component.config or component
              );
            }
          ) implementations
        ) desktop.components
      );

      model = desktop.normalize {
        inherit cfg;
        apps = config.ltp.apps.facts;
        keyboard = config.ltp.locale.keyboard.session;
        facts = config.ltp.hardware.facts;
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
        (desktop.systemdUnits {
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
            # The uwsm-managed session the greeter offers.
            programs.uwsm = {
              enable = true;
              waylandCompositors.${name} = entry.uwsm;
            };

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
                      desktop.waybarConfig {
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

      #
      # Only the uwsm sessions: the desktop relies on uwsm (uwsm app,
      # uwsm finalize, XDG_CURRENT_DESKTOP for the per-session units).
      #
      uwsmSessions = pkgs.symlinkJoin {
        name = "uwsm-sessions";
        paths = builtins.filter (
          package: builtins.any (lib.hasSuffix "-uwsm") (package.providedSessions or [ ])
        ) config.services.displayManager.sessionPackages;
      };

      greeter =
        if model.greeter.name == null then
          null
        else
          desktop.greeters.${model.greeter.name} {
            inherit pkgs;
            sessionsDir = "${uwsmSessions}/share/wayland-sessions";
          };

      format = diagnostic: "ltp.desktop [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      imports = componentModules;

      config = mkMerge [

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
                  services.dbus.enable = true;

                  services.greetd = mkIf (greeter != null) {
                    enable = true;
                    useTextGreeter = true;

                    settings.default_session = {
                      inherit (greeter) command;
                      user = "greeter";
                    };
                  };

                  home-manager.sharedModules = [
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
