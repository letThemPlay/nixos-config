{
  inputs,
  lib,
  findFilesWithExt,
  ...
}:
let
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
    inherit importAscFiles;
  };
}
