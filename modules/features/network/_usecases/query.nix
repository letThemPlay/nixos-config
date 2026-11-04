{ lib }:
let
  inherit (lib)
    attrByPath
    attrNames
    attrValues
    hasAttr
    ;

  links = model: attrValues model.links;

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

  wirelessBackend = model: if hasWireless model then model.wireless.backend else null;

  #
  # Whether a networkd match glob (*, ?, [...]) matches an interface
  # name. Other regex characters in the glob are taken literally.
  #
  matchesGlob =
    glob: name:
    let
      special = [
        "."
        "+"
        "("
        ")"
        "{"
        "}"
        "^"
        "$"
        "|"
        "\\"
      ];

      escaped = lib.replaceStrings special (map (c: "\\" + c) special) glob;

      regex = lib.replaceStrings [ "*" "?" ] [ ".*" "." ] escaped;
    in
    builtins.match regex name != null;

  # Name of the backend unit for a link.
  unitName = link: "${toString link.priority}-${link.id}";
in
{
  inherit
    all
    ids
    has
    get
    filter
    enabled
    byKind
    wired
    wireless
    hasWireless
    wirelessBackend
    matchesGlob
    unitName
    ;
}
