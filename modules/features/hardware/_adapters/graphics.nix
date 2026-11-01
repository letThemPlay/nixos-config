{ lib, hardware }:

#
# Graphics settings as plain data; the hardware module maps them to
# hardware.graphics, services.xserver.videoDrivers and hardware.nvidia.
#
{ model }:

let
  inherit (hardware) query;

  gpus = query.all model;

  nvidia = query.nvidiaGpu model;

  integrated = query.integratedGpu model;

  inherit (model.prime) mode active;
in
{
  enable = gpus != [ ];

  # In a PRIME pair the nvidia driver also drives the integrated GPU.
  videoDrivers =
    if active then
      [ "nvidia" ]
    else
      lib.unique (map (gpu: hardware.gpuVendors.${gpu.vendor}.driver) gpus);

  nvidia =
    if nvidia == null then
      null
    else
      {
        modesetting.enable = true;

        powerManagement = {
          enable = true;
          # Powering the dGPU down needs offload; NixOS asserts it.
          finegrained = active && mode == "offload";
        };

        open = true;
        nvidiaSettings = true;

        prime = lib.optionalAttrs active {
          offload = {
            enable = mode == "offload";
            enableOffloadCmd = mode == "offload";
          };

          sync.enable = mode == "sync";

          nvidiaBusId = nvidia.busId;

          ${hardware.gpuVendors.${integrated.vendor}.primeField} = integrated.busId;
        };
      };

  #
  # Forcing nvidia for GBM, GLX and VA-API only makes sense when nvidia
  # renders the display; with offload it would defeat the offload.
  #
  environment =
    lib.optionalAttrs (query.nvidiaPrimary model) {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
    }
    // lib.optionalAttrs (nvidia != null) {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
}
