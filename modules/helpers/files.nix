#
# Repository plumbing shared by the flake-parts modules, as
# config.ltp.lib. Not related to nixpkgs `lib`.
#
{ lib, ... }:
{
  options.ltp.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Helper functions for the flake-parts modules.";
  };

  # The files with extension `ext` directly in `dir`; empty if `dir` does not exist.
  config.ltp.lib.findFilesWithExt =
    ext: dir:
    let
      suffix = ".${ext}";
    in
    if builtins.pathExists dir then
      dir
      |> builtins.readDir
      |> lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix suffix name)
      |> lib.mapAttrsToList (name: _: dir + "/${name}")
    else
      [ ];
}
