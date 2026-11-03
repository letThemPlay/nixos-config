_:

#
# systemd-boot: unsigned boot entries, EFI variables written by the
# installer.
#
{ model }:

{
  settings.configurationLimit = model.generations;

  canTouchEfiVariables = true;

  packages = [ ];

  state.directories = [ ];
}
