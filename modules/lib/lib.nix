{ inputs, lib, ... }:
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

  importAscFiles =
    username:
    (inputs.self + "/gpg/${username}")
    |> findFilesWithExt "asc"
    |> lib.forEach (filePath: {
      source = filePath;
      trust = 5;
    });
in
{
  _module.args = {
    inherit findFilesWithExt importAscFiles;
  };
}
