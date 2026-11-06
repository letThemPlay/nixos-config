{ config, lib, ... }:
let
  theme = config.ltp.features.theme;

  inherit (config.flake.nixosModules) theme-options;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        theme-options
        { ltp.theme = settings; }
      ];
    }).config.ltp.theme;

  usersWith = themes: lib.mapAttrs (_: name: { theme = name; }) themes;

  modelOf =
    settings: themes:
    theme.normalize {
      cfg = evalCfg settings;
      users = usersWith themes;
    };

  codesOf = model: lib.sort lib.lessThan (map (d: d.code) (theme.validate.all model).diagnostics);

  contractCases = [
    {
      settings = { };
      themes = { };
    }
    {
      settings.appearance.cursor.size = 32;
      themes.alice = "catppuccin";
    }
    {
      settings = { };
      themes.bob = "nope";
    }
    {
      settings.appearance.icons.pack = "papirus";
      themes.carol = "tokyonight";
    }
    {
      settings.appearance.icons.pack = "nope";
      themes.dave = "catppuccin";
    }
  ];

  # A bare model for the catalogue-wide checks.
  noUsers = {
    users = { };
    appearance.icons.pack = "tela";
  };

  iconsOf =
    pack: themeName: (modelOf { appearance.icons.pack = pack; } { u = themeName; }).users.u.icons;

  tests = {

    testResolvesTheme = {
      expr =
        let
          user = (modelOf { } { alice = "catppuccin"; }).users.alice;
        in
        {
          inherit (user)
            theme
            known
            scheme
            polarity
            icons
            ;
          wallpaper = baseNameOf user.wallpaper;
        };
      expected = {
        theme = "catppuccin";
        known = true;
        scheme = "catppuccin-macchiato";
        polarity = "dark";
        icons = {
          package = "tela-icon-theme";
          override = null;
          dark = "Tela-purple-dark";
          light = "Tela-purple-light";
        };
        wallpaper = "catppuccin.png";
      };
    };

    testEveryCatalogueThemeIsValid = {
      expr = lib.mapAttrs (name: _: codesOf (modelOf { } { alice = name; })) theme.themes;
      expected = lib.mapAttrs (_: _: [ ]) theme.themes;
    };

    testUnknownTheme = {
      expr =
        let
          model = modelOf { } { alice = "nope"; };
        in
        {
          inherit (model.users.alice) known wallpaper icons;
          codes = codesOf model;
        };
      expected = {
        known = false;
        wallpaper = null;
        icons = null;
        codes = [ "theme.user.unknown" ];
      };
    };

    testMissingWallpaper = {
      expr =
        let
          broken = theme // {
            themes.broken = {
              wallpaper = "missing.png";
              scheme = "x";
              polarity = "dark";
            };
          };
          validate = import ../features/theme/_usecases/validate.nix {
            inherit lib;
            theme = broken;
            inherit (config.ltp.features) diagnostics;
          };
        in
        map (d: d.code) (validate.all noUsers).diagnostics;
      expected = [ "theme.wallpaper.missing" ];
    };

    # Tela names each accent; Papirus recolours by override.
    testIconPackNaming = {
      expr = {
        tela = iconsOf "tela" "tokyonight";
        papirus = iconsOf "papirus" "tokyonight";
        telaPlain = theme.iconPacks.tela.name {
          accent = null;
          polarity = "light";
        };
      };
      expected = {
        tela = {
          package = "tela-icon-theme";
          override = null;
          dark = "Tela-blue-dark";
          light = "Tela-blue-light";
        };
        papirus = {
          package = "papirus-icon-theme";
          override.color = "blue";
          dark = "Papirus-Dark";
          light = "Papirus-Light";
        };
        telaPlain = "Tela-light";
      };
    };

    testUnknownIconPack = {
      expr =
        let
          model = modelOf { appearance.icons.pack = "nope"; } { alice = "catppuccin"; };
        in
        {
          inherit (model.users.alice) icons;
          codes = codesOf model;
        };
      expected = {
        icons = null;
        codes = [ "theme.icons.pack.unknown" ];
      };
    };

    # Papirus has no purple: catppuccin keeps Papirus's own folders and warns.
    testAccentMissingFromPack = {
      expr =
        let
          model = modelOf { appearance.icons.pack = "papirus"; } { alice = "catppuccin"; };
        in
        {
          inherit (model.users.alice.icons) override dark;
          diagnostics = map (d: {
            inherit (d) code severity target;
          }) (theme.validate.all model).diagnostics;
        };
      expected = {
        override = null;
        dark = "Papirus-Dark";
        diagnostics = [
          {
            code = "theme.icons.accent.unknown";
            severity = "warning";
            target = "alice";
          }
        ];
      };
    };

    # Every theme's accent is one the default pack has.
    testCatalogueAccentsInDefaultPack = {
      expr = lib.filterAttrs (
        _: entry:
        (entry.iconAccent or null) != null
        && !(lib.elem entry.iconAccent theme.iconPacks.${(evalCfg { }).appearance.icons.pack}.accents)
      ) theme.themes;
      expected = { };
    };

    # The defaults are the values every host had before the feature.
    testAppearanceDefaults = {
      expr = removeAttrs (evalCfg { }).appearance [ "ui" ];
      expected = {
        fontSize = {
          terminal = 11;
          applications = 12;
          desktop = 10;
        };
        fonts = {
          monospace = {
            package = "nerd-fonts.jetbrains-mono";
            name = "JetBrainsMono Nerd Font";
          };
          sansSerif = {
            package = "dejavu_fonts";
            name = "DejaVu Sans";
          };
          extra = [ "nerd-fonts.symbols-only" ];
        };
        cursor = {
          package = "bibata-cursors";
          name = "Bibata-Modern-Ice";
          size = 24;
        };
        icons.pack = "tela";
      };
    };

    # Interfaces reach every colour through a role, and roles only name slots
    # a base16 scheme has.
    testUiPaletteSlots = {
      expr = builtins.filter (slot: builtins.match "base0[0-9A-F]" slot == null) (
        builtins.attrValues theme.uiPalette
      );
      expected = [ ];
    };

    # One setting moves its whole scale, so components stay in proportion.
    testUiTokenScales = {
      expr =
        let
          tokens =
            (modelOf {
              appearance = {
                ui = {
                  spacing = 5;
                  radius = 8;
                  animationMs = 200;
                };
                fontSize.desktop = 11;
                fonts.sansSerif.name = "Inter";
              };
            } { }).ui;
        in
        {
          inherit (tokens) space radius motion;
          barPadding = tokens.size.bar - tokens.size.barItem;
          family = tokens.font.family;
          body = tokens.font.body;
          small = tokens.font.small;
          iconMedium = tokens.icon.medium;
        };
      expected = {
        space = {
          xs = 5;
          sm = 10;
          md = 15;
          lg = 20;
          xl = 30;
        };
        radius = {
          sm = 4;
          md = 6;
          lg = 8;
        };
        motion = {
          fast = 100;
          normal = 200;
        };
        barPadding = 15;
        family = "Inter";
        body = 11;
        small = 10;
        iconMedium = 25;
      };
    };

    testUiIconDefaults = {
      expr = {
        inherit ((modelOf { } { }).ui.icon) package name;
      };
      expected = {
        package = "material-symbols";
        name = "Material Symbols Rounded";
      };
    };

    testStylixAdapter = {
      expr =
        let
          inherit
            (theme.stylix {
              model = modelOf { appearance.fontSize.terminal = 14; } {
                alice = "tokyonight";
                bob = "nope";
              };
            })
            users
            ;
        in
        {
          names = lib.attrNames users;
          inherit (users.alice) scheme polarity;
          image = baseNameOf users.alice.image;
          terminal = users.alice.fonts.sizes.terminal;
          cursor = users.alice.cursor.name;
          inherit (users.alice) icons;
        };
      expected = {
        names = [ "alice" ];
        scheme = "tokyo-night-dark";
        polarity = "dark";
        image = "tokyonight.png";
        terminal = 14;
        cursor = "Bibata-Modern-Ice";
        icons = {
          package = "tela-icon-theme";
          override = null;
          dark = "Tela-blue-dark";
          light = "Tela-blue-light";
        };
      };
    };

    testModelContract = {
      expr = map (
        case:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = theme.types.model; }; }
                { model = modelOf case.settings case.themes; }
              ];
            }).config.model;
        in
        builtins.deepSeq checked true
      ) contractCases;
      expected = map (_: true) contractCases;
    };

  };
in
{
  perSystem =
    { pkgs, ... }:
    let
      failures = lib.runTests tests;
    in
    {
      checks.theme-unit =
        if failures == [ ] then
          pkgs.runCommand "theme-unit-tests" { } "touch $out"
        else
          throw "theme unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
