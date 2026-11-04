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
              component = import path (args // { inherit pkgs desktop; });
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

      # The unified shell draws its own bar from the same layout lists.
      waybarBar = barModules != [ ] && cfg.components.bar != desktop.uiComponent;

      tokens = config.ltp.theme.facts.ui;

      # The locker is its own short-lived instance (_ui/lock.qml).
      shellSurfaces = lib.remove "locker" model.ui.surfaces;

      iconThemeOf =
        { config, osConfig }:
        let
          polarity = osConfig.ltp.theme.facts.users.${config.home.username}.polarity or "dark";
        in
        tokens.icon.theme.${polarity};

      #
      # One user's shell config: the QML as real files (Quickshell resolves
      # imports relative to the files, which symlinks into the store break),
      # with that user's generated theme and settings beside it.
      #
      shellConfig =
        { config, osConfig }:
        let
          terminal = osConfig.ltp.apps.facts.terminal or null;

          wallpaper = osConfig.ltp.theme.facts.users.${config.home.username}.wallpaper or null;
        in
        pkgs.runCommand "ltp-shell"
          {
            theme = desktop.quickshell.theme {
              inherit tokens;
              colors = config.lib.stylix.colors;
            };

            settings = desktop.quickshell.settings {
              inherit model;
              inherit (desktop) spawnPrefix;

              pam = {
                config = "ltp-lock";
                directory = "/etc/pam.d";
              };

              wallpaper = if wallpaper == null then "" else "${wallpaper}";

              terminal =
                if terminal == null then
                  [ ]
                else
                  terminal.command ++ lib.optional ((terminal.execFlag or null) != null) terminal.execFlag;
            };

            passAsFile = [
              "theme"
              "settings"
            ];
          }
          ''
            cp -r ${desktop.uiSource} $out
            chmod -R u+w $out
            cp $themePath $out/common/Theme.qml
            cp $settingsPath $out/common/Settings.qml
          '';

      shellServices = lib.optionalAttrs (shellSurfaces != [ ]) {
        shell = {
          description = "Unified shell";
          restart = "on-failure";
          compositors = null;

          exec =
            args:
            let
              iconTheme = iconThemeOf args;
            in
            [
              "${pkgs.coreutils}/bin/env"
              "QS_ICON_THEME=${iconTheme}"
              "${pkgs.quickshell}/bin/qs"
              "-c"
              desktop.uiInstance.name
            ];
        };
      };

      #
      # One bar per enabled compositor, each started only in its own
      # session, so several compositors can be offered at login.
      #
      barServices = lib.optionalAttrs waybarBar (
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
            services = model.services // barServices // shellServices;
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

            environment.systemPackages = map (package: pkgs.${package}) entry.system.packages;

            home-manager.sharedModules = [
              {
                xdg.configFile = {
                  ${entry.configFile}.text = entry.render {
                    inherit model;
                    inherit (desktop) spawnPrefix;
                  };

                  "waybar/${name}.json" = mkIf waybarBar {
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

                (mkIf (model.ui.surfaces != [ ]) {
                  fonts.packages = [ (lib.getAttrFromPath (lib.splitString "." tokens.icon.package) pkgs) ];

                  home-manager.sharedModules = [
                    (
                      { config, osConfig, ... }:
                      {
                        home.packages = [
                          pkgs.quickshell
                          (lib.getAttrFromPath (lib.splitString "." tokens.icon.theme.package) pkgs)
                        ];

                        xdg.configFile."quickshell/${desktop.uiInstance.name}".source = shellConfig {
                          inherit config osConfig;
                        };
                      }
                    )
                  ];
                })
              ]

              ++ mapAttrsToList renderCompositor desktop.compositors
            )
          ))

        ]))

      ];
    };
}
