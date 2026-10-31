{ lib }:
let
  inherit (lib)
    attrByPath
    attrNames
    attrValues
    hasAttr
    ;

  links = model: attrValues model.links;
in

rec {

  #
  # Primitive Queries
  #

  all = links;

  ids = model: attrNames model.links;

  has = model: id: hasAttr id model.links;

  get =
    model: id:
    assert builtins.isString id;
    attrByPath [ id ] null model.links;

  filter =
    model: predicate:
    assert builtins.isFunction predicate;
    builtins.filter predicate (all model);

  #
  # Semantic Queries
  #

  enabled = model: filter model (link: link.enable);

  byKind =
    model: kind:
    assert builtins.isString kind;
    builtins.filter (link: link.kind == kind) (enabled model);

  wired = model: byKind model "wired";

  wireless = model: byKind model "wireless";

  #
  # Derived Facts
  #

  # True when an enabled link needs the wireless backend.
  hasWireless = model: wireless model != [ ];

  # Name of the backend unit for a link.
  unitName = link: "${toString link.priority}-${link.id}";

}
