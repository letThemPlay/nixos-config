{ lib, ... }: {
  options.ltp.theme.catalog = lib.mkOption {
    description = "The central structural metadata blueprint for all visual profiles.";
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          imageName = lib.mkOption { type = lib.types.str; };
          schemeName = lib.mkOption { type = lib.types.str; };
          polarity = lib.mkOption {
            type = lib.types.str;
            default = "dark";
          };
        };
      }
    );
  };
}
