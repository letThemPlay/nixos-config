{ lib, desktop }:

#
# systemd user units for the background components, as plain data in
# home-manager's systemd.user.services shape. exec stays as given (a
# list, or a function of the user's home-manager config); the desktop
# module resolves and escapes it.
#
{ model }:

{
  units = lib.mapAttrs (_: service: {
    inherit (service) exec;

    Unit = {
      Description = service.description;
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    }
    // lib.optionalAttrs (service.compositors != null) {
      # uwsm exports the session's desktop name to the user manager;
      # "|" makes the conditions alternatives.
      ConditionEnvironment = map (
        name: "|XDG_CURRENT_DESKTOP=${desktop.compositors.${name}.session or name}"
      ) service.compositors;
    };

    Service.Restart = service.restart;

    Install.WantedBy = [ "graphical-session.target" ];
  }) model.services;
}
