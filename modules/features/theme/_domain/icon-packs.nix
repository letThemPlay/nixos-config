#
# Icon packs a host can choose, as plain data. A theme's accent reaches
# a pack in one of two ways: Tela ships every colour as its own theme
# name, while Papirus recolours its folders through a package override.
# So each pack says how a variant is named and, if it recolours by
# override, which argument takes the accent.
#
_: {

  tela = {
    package = "tela-icon-theme";

    accents = [
      "black"
      "blue"
      "brown"
      "dracula"
      "green"
      "grey"
      "manjaro"
      "nord"
      "orange"
      "pink"
      "purple"
      "red"
      "ubuntu"
      "yellow"
    ];

    # Tela, Tela-dark, Tela-purple-dark, …
    name = { accent, polarity }: "Tela${if accent == null then "" else "-${accent}"}-${polarity}";

    override = null;
  };

  papirus = {
    package = "papirus-icon-theme";

    # The colours papirus-folders knows.
    accents = [
      "adwaita"
      "black"
      "blue"
      "bluegrey"
      "breeze"
      "brown"
      "carmine"
      "cyan"
      "darkcyan"
      "deeporange"
      "green"
      "grey"
      "indigo"
      "magenta"
      "nordic"
      "orange"
      "palebrown"
      "paleorange"
      "pink"
      "red"
      "teal"
      "violet"
      "white"
      "yaru"
      "yellow"
    ];

    name = { polarity, ... }: if polarity == "dark" then "Papirus-Dark" else "Papirus-Light";

    override = "color";
  };

}
