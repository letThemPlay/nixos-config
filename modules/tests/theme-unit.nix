{ config, lib, ... }:
let
  theme = config.flake.subsystems.theme;

  inherit (config.flake.nixosModules) theme-api;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        theme-api
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
  ];

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
            ;
          wallpaper = baseNameOf user.wallpaper;
        };
      expected = {
        theme = "catppuccin";
        known = true;
        scheme = "catppuccin-macchiato";
        polarity = "dark";
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
          inherit (model.users.alice) known wallpaper;
          codes = codesOf model;
        };
      expected = {
        known = false;
        wallpaper = null;
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
          validate = import ../subsystems/theme/_usecases/validate.nix {
            inherit lib;
            theme = broken;
            inherit (config.flake.subsystems) diagnostics;
          };
        in
        map (d: d.code) (validate.all { users = { }; }).diagnostics;
      expected = [ "theme.wallpaper.missing" ];
    };

    # The defaults are the values every host had before the subsystem.
    testAppearanceDefaults = {
      expr = (evalCfg { }).appearance;
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
        };
      expected = {
        names = [ "alice" ];
        scheme = "tokyo-night-dark";
        polarity = "dark";
        image = "tokyonight.png";
        terminal = 14;
        cursor = "Bibata-Modern-Ice";
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
