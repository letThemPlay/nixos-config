#
# Repository plumbing passed to every flake-parts module as an argument.
# Not related to nixpkgs `lib`.
#
{ lib, ... }:
let
  findFilesWithExt =
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
in
{
  _module.args = {
    inherit findFilesWithExt;
  };
}
