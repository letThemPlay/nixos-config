{ inputs }:
let
  inherit (inputs.nixpkgs.lib) hasSuffix mapAttrsToList filterAttrs;
  inherit (inputs) self;
in
{
  importAscFiles =
    username:
    let
      ascPath = "${self}/gpg/${username}";
      filterAscFiles = k: v: v == "regular" && hasSuffix ".asc" k;
    in
    if builtins.pathExists ascPath then
      let
        validFiles = filterAttrs filterAscFiles (builtins.readDir ascPath);
      in
      if validFiles != { } then
        (mapAttrsToList (name: _: {
          source = ascPath + ("/" + name);
          trust = 5;
        }) validFiles)
      else
        [ ]
    else
      [ ];
}
