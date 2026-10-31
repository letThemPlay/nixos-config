#
# Partial overrides shared by the subsystem cores: a host or feature
# sets some fields of a layout/profile/default entry, and normalize
# merges exactly those over it.
#
# A field counts as set when it has a definition (any priority above
# the option default), not when it is non-null, so a field that is itself nullable (a volume's mountpoint,
# a terminal's execFlag) can be overridden to null. For fields that are
# not nullable, null still means "not set".
#
# fields : attrset of { type; description; } — the entry's field specs.
#
{ lib, ... }:
let
  inherit (lib)
    attrNames
    elem
    filter
    filterAttrs
    mapAttrs
    mkOption
    types
    ;

  nullable = spec: spec.type.check null;
in
{
  flake.subsystems.overrides = {

    type =
      fields:
      types.submodule (
        { options, ... }:
        {
          options =
            mapAttrs (
              _: spec:
              mkOption {
                # The field's own type when it allows null already.
                type = if nullable spec then spec.type else types.nullOr spec.type;
                default = null;
                inherit (spec) description;
              }
            ) fields
            // {
              _defined = mkOption {
                type = types.listOf types.str;
                internal = true;
                readOnly = true;
                # The default is itself a definition at mkOptionDefault
                # priority (1500); real definitions take precedence over it.
                default = filter (name: options.${name}.highestPrio < 1500) (attrNames fields);
                description = "Fields this override defines.";
              };
            };
        }
      );

    #
    # base with the override's defined fields. Plain-data overrides
    # without _defined fall back to "non-null means set".
    #
    apply =
      fields: base: override:
      let
        defined = override._defined or (attrNames (filterAttrs (_: value: value != null) override));
      in
      base
      // filterAttrs (name: value: elem name defined && (value != null || nullable fields.${name})) (
        removeAttrs override [ "_defined" ]
      );

  };
}
