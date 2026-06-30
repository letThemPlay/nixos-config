{ lib }: {
  findFilesWithExt =
    ext: dir:
    let
      suffix = ".${ext}";
    in
    if builtins.pathExists dir then
      lib.mapAttrsToList (name: _: dir + "/${name}") (
        lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix suffix name) (builtins.readDir dir)
      )
    else
      [ ];
}
