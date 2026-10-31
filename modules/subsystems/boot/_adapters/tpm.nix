_:

#
# TPM2 unlock of the root LUKS volume. The key is enrolled once by
# hand; this only tells systemd's initrd to try the TPM first.
#
{ model }:

let
  inherit (model.tpmUnlock) enable luksName;
in
{
  active = enable && luksName != null;

  inherit luksName;

  crypttabExtraOpts = [ "tpm2-device=auto" ];

  packages = [ "tpm2-tss" ];
}
