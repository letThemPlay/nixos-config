{ lib, ... }: {
  options.flake.library = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Custom library functions merged across modules.";
  };
}
