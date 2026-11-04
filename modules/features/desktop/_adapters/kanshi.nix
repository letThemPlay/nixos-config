{ lib }:

#
# Display profiles as home-manager's services.kanshi.settings. kanshi applies
# the profile whose outputs match what's connected, through the compositor's
# output management, so this has nothing compositor-specific in it.
#
{ displays }:

let
  inherit (lib) mapAttrsToList optionalAttrs;

  output =
    criteria: settings:
    {
      inherit criteria;
      status = if settings.enable then "enable" else "disable";
    }
    // optionalAttrs (settings.scale != null) { inherit (settings) scale; }
    // optionalAttrs (settings.mode != null) { inherit (settings) mode; }
    // optionalAttrs (settings.position != null) {
      position = "${toString settings.position.x},${toString settings.position.y}";
    };
in
mapAttrsToList (name: profile: {
  profile = {
    inherit name;
    outputs = mapAttrsToList output profile.outputs;
  };
}) displays.profiles
