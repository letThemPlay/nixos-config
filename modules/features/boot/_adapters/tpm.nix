_:

#
# TPM2 unlock of the root LUKS volume. The key is enrolled once by
# hand; this only tells systemd's initrd to try the TPM first.
#
{ model }:

let
  inherit (model.tpmUnlock) enable luksName;

  active = enable && luksName != null;
in
{
  inherit active;

  # boot.initrd.luks.devices entries, merged with the ones disko defines.
  devices = if active then { ${luksName}.crypttabExtraOpts = [ "tpm2-device=auto" ]; } else { };

  packages = if active then [ "tpm2-tss" ] else [ ];
}
