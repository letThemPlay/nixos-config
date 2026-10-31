{ lib }:
let
  inherit (lib) attrNames attrValues filterAttrs;
in
{

  all = model: attrValues model.users;

  names = model: attrNames model.users;

  get = model: name: model.users.${name} or null;

  #
  # Takes the users attrset rather than the model, so feature modules
  # can pass the published facts directly:
  #
  #   identity.query.withFeature config.ltp.identity.facts.users "flashgbx"
  #
  withFeature = users: feature: filterAttrs (_: user: builtins.elem feature user.features) users;

  admins = model: filterAttrs (_: user: user.admin) model.users;

}
