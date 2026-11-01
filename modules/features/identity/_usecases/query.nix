{ lib }:
let
  inherit (lib) attrNames attrValues filterAttrs;
in
{

  all = model: attrValues model.users;

  names = model: attrNames model.users;

  get = model: name: model.users.${name} or null;

  #
  # Takes the users attrset rather than the model, so modules
  # can pass the published facts directly:
  #
  #   identity.query.withBundle config.ltp.identity.facts.users "flashgbx"
  #
  withBundle = users: bundle: filterAttrs (_: user: builtins.elem bundle user.bundles) users;

  admins = model: filterAttrs (_: user: user.admin) model.users;

}
