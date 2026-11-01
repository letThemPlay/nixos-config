_:

#
# BlueZ with blueman, powered on at boot. Paired devices and adapter
# settings live in /var/lib/bluetooth and are preserved.
#
{ model }:

{
  active = model.bluetooth;

  powerOnBoot = true;

  state.directories = [ "/var/lib/bluetooth" ];
}
