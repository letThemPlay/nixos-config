{ lib, bundles }:
let
  inherit (lib)
    attrNames
    filter
    filterAttrs
    mapAttrs
    ;
in

#
# cfg is the ltp.bundles option set. catalog defaults to the core's; the
# unit test passes its own to check broken entries. No module system is
# required.
#
{
  cfg,
  catalog ? bundles.catalog,
}:

let
  requiresOf = name: catalog.${name}.requires or [ ];

  # The selection and everything it requires, in selection order.
  active = map (item: item.key) (
    builtins.genericClosure {
      startSet = map (name: { key = name; }) cfg.selected;
      operator = item: map (name: { key = name; }) (requiresOf item.key);
    }
  );
in
{
  inherit (cfg) selected;

  inherit active;

  unknown = filter (name: !(catalog ? ${name})) active;

  unknownRequires = filterAttrs (_: missing: missing != [ ]) (
    mapAttrs (_: entry: filter (name: !(catalog ? ${name})) (entry.requires or [ ])) catalog
  );

  known = attrNames catalog;
}
