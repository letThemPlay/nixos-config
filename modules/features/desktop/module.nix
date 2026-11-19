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
        tunnels = config.ltp.network.facts.tunnels;
        themes = lib.attrNames (lib.filterAttrs (_: user: user.known) config.ltp.theme.facts.users);
        users = lib.attrNames config.ltp.identity.facts.users;
      };

      validation = desktop.validate.all model;

      enabled = map (c: c.name) (filter (c: c.known) model.compositors);

      barModules = model.bar.left ++ model.bar.center ++ model.bar.right;

      # The unified shell draws its own bar from the same layout lists.
      waybarBar = barModules != [ ] && cfg.components.bar != desktop.uiComponent;

      tokens = config.ltp.theme.facts.ui;

      # The locker is its own short-lived instance (_ui/lock.qml).
      shellSurfaces = lib.remove "locker" model.ui.surfaces;

      #
      # The user's icon pack in their theme's accent, as the theme feature
      # resolved it, so the dock matches the apps. hicolor, the base every
      # pack inherits, when the user has no themed icons.
      #
      iconsOf =
        { config, osConfig }: osConfig.ltp.theme.facts.users.${config.home.username}.icons or null;

      iconThemeOf =
        args:
        let
          icons = iconsOf args;
          polarity = args.osConfig.ltp.theme.facts.users.${args.config.home.username}.polarity or "dark";
        in
        if icons == null then "hicolor" else icons.${polarity};

      # The same derivation stylix installs, so the two never collide.
      iconPackageOf =
        args:
        let
          icons = iconsOf args;
          package = lib.getAttrFromPath (lib.splitString "." icons.package) pkgs;
        in
        lib.optional (icons != null) (
          if icons.override == null then package else package.override icons.override
        );

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

      sessionsDir = "${uwsmSessions}/share/wayland-sessions";

      greeterEntry = if model.greeter.name == null then null else desktop.greeters.${model.greeter.name};

      niri = config.programs.niri.package;

      # The sessions as data for a graphical greeter: Name, Exec and DesktopNames.
      greeterSessions =
        pkgs.runCommand "ltp-greeter-sessions.json" { nativeBuildInputs = [ pkgs.jq ]; }
          ''
            for file in ${sessionsDir}/*.desktop; do
              jq -n \
                --arg name "$(sed -n 's/^Name=//p' "$file" | head -n 1)" \
                --arg exec "$(sed -n 's/^Exec=//p' "$file" | head -n 1)" \
                --arg desktopNames "$(sed -n 's/^DesktopNames=//p' "$file" | head -n 1)" \
                '{ $name, $exec, $desktopNames }'
            done | jq -s . > $out
          '';

      #
      # The graphical greeter's QML: the shell's source with the theme of
      # the user it wears (validation ensures there is one) and the
      # greeter's own settings, as no user is logged in yet.
      #
      greeterUi =
        let
          user = model.greeter.themeUser;
          wallpaper = config.ltp.theme.facts.users.${user}.wallpaper or null;
        in
        pkgs.runCommand "ltp-greeter"
          {
            theme = desktop.quickshell.theme {
              inherit tokens;
              colors = config.home-manager.users.${user}.lib.stylix.colors;
            };

            settings = desktop.quickshell.greeterSettings {
              inherit model;
              inherit (desktop) powerActions;
              sessionsFile = "${greeterSessions}";
              wallpaper = if wallpaper == null then "" else "${wallpaper}";
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

      greeterState = "/var/lib/ltp-greeter";

      graphicalGreeter = cfg.greeter != null && (desktop.greeters.${cfg.greeter}.graphical or false);

      #
      # What the greeter's niri runs. greetd starts the session once the
      # greeter exits, so niri quits when the greeter does, whether it
      # launched a session or crashed (greetd then starts a fresh greeter).
      #
      greeterStart = pkgs.writeShellScript "ltp-greeter-start" ''
        export PATH=/run/wrappers/bin:/run/current-system/sw/bin
        export XDG_STATE_HOME=${greeterState}
        ${pkgs.quickshell}/bin/qs --path ${greeterUi}/greeter.qml
        ${niri}/bin/niri msg action quit --skip-confirmation
      '';

      greeter =
        if greeterEntry == null then
          null
        else
          {
            inherit (greeterEntry) graphical;

            command = greeterEntry.command (
              {
                inherit pkgs sessionsDir;
              }
              // lib.optionalAttrs greeterEntry.graphical {
                inherit niri;
                niriConfig = pkgs.writeText "ltp-greeter-niri.kdl" (
                  greeterEntry.niriConfig {
                    inherit (model) keyboard;
                    start = "${greeterStart}";
                  }
                );
              }
            );
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
          # A graphical greeter remembers the last user and session in its
          # own state directory, which must survive an ephemeral root. This
          # reads only the greeter option and the registry: the model reads
          # other features, and storage reads this (infinite recursion).
          #
          (mkIf graphicalGreeter {
            systemd.tmpfiles.settings.ltp-greeter.${greeterState}.d = mkIf (!config.ltp.storage.enable) {
              user = "greeter";
              group = "greeter";
              mode = "0750";
            };

            ltp.storage.persistence.state.directories = mkIf config.ltp.storage.enable [
              {
                directory = greeterState;
                user = "greeter";
                group = "greeter";
                mode = "0750";
              }
            ];
          })

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
                    useTextGreeter = !greeter.graphical;

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
                        home.packages = [ pkgs.quickshell ] ++ iconPackageOf { inherit config osConfig; };

                        xdg.configFile."quickshell/${desktop.uiInstance.name}".source = shellConfig {
                          inherit config osConfig;
                        };
                      }
                    )
                  ];
                })

                (mkIf (greeter != null && greeter.graphical) {
                  fonts.packages = [ (lib.getAttrFromPath (lib.splitString "." tokens.icon.package) pkgs) ];
                })
              ]

              ++ mapAttrsToList renderCompositor desktop.compositors
            )
          ))

        ]))

      ];
    };
}
