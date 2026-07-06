_: {
  flake.nixosModules.nvidia-graphics = { config, ... }: {

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;

      powerManagement.enable = true;
      powerManagement.finegrained = true;

      open = true;

      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.stable;

      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        # ⚠️ CRITICAL DEVICE ROUTING ASSIGNMENTS:
        # You must cross-check these hex values against your machine's local terminal path logs!
        # Run: 'lspci | grep -E "VGA|3D"' to locate your exact PCI bus mapping markers.
        amdgpuBusId = "PCI:0:2:0"; # 🔌 Ingests your integrated CPU bus layout marker (Swap to amdgpuBusId if running Ryzen!)
        nvidiaBusId = "PCI:1:0:0"; # 🚀 Ingests your proprietary RTX 3070 dGPU bus layout marker
      };
    };

    environment.variables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };
}
