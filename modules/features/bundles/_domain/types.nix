{ lib }:
let
  inherit (lib) mkOption types;

  entry = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        description = "What the bundle turns on, for the README and error messages.";
      };

      requires = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Bundles this one builds on; they are applied with it.";
      };
    };
  };

  model = types.submodule {
    options = {

      selected = mkOption {
        type = types.listOf types.str;
        description = "Bundles the host names, as given.";
      };

      active = mkOption {
        type = types.listOf types.str;
        description = "The selection with every bundle it requires, each once.";
      };

      unknown = mkOption {
        type = types.listOf types.str;
        description = "Selected names that are not in the catalogue.";
      };

      unknownRequires = mkOption {
        type = types.attrsOf (types.listOf types.str);
        description = "Catalogue entries that require bundles the catalogue lacks.";
      };

      known = mkOption {
        type = types.listOf types.str;
        description = "Every bundle name in the catalogue.";
      };

    };
  };
in
{
  inherit entry model;
}
