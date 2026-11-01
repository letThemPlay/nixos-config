_:

#
# lanzaboote: signs the boot files with the keys in pkiBundle. The
# boot order is managed with sbctl, not the installer.
#
{ model }:

{
  settings = {
    inherit (model.secureBoot) pkiBundle;

    configurationLimit = model.generations;
  };

  canTouchEfiVariables = false;

  packages = [ "sbctl" ];

  # Losing the keys leaves the machine unable to sign new generations.
  state.directories = [ model.secureBoot.pkiBundle ];
}
