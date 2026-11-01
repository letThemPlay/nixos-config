{ lib }:

#
# agenix settings as plain data; the secrets module applies them.
#
{ model }:

{
  inherit (model.identity) paths;

  secrets = lib.mapAttrs (_: file: {
    file = file.source;
    inherit (file) owner group mode;
  }) model.files;
}
