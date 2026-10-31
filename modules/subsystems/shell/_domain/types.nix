{ lib }:
let
  inherit (lib) mkOption types;
in
rec {

  # A user's shell, resolved against the registry.
  userShell = types.submodule {
    options = {

      shell = mkOption {
        type = types.str;
        description = "Shell name the user chose.";
      };

      known = mkOption {
        type = types.bool;
        description = "Whether the shell is in the shell registry.";
      };

    };
  };

  model = types.submodule {
    options = {

      aliases = mkOption {
        type = types.attrsOf types.str;
        description = "Defaults merged with contributed aliases.";
      };

      users = mkOption {
        type = types.attrsOf userShell;
      };

      shells = mkOption {
        type = types.listOf types.str;
        description = "Registered shells some user logs in with.";
      };

    };
  };

}
