{ config, lib, ... }:
let
  hardware = config.flake.features.hardware;

  inherit (config.flake.nixosModules) hardware-api;

  evalCfg =
    settings:
    (lib.evalModules {
      modules = [
        hardware-api
        { ltp.hardware = settings; }
      ];
    }).config.ltp.hardware;

  modelOf = settings: hardware.normalize (evalCfg settings);

  codes =
    settings:
    lib.sort lib.lessThan (map (d: d.code) (hardware.validate.all (modelOf settings)).diagnostics);

  graphicsOf = settings: hardware.graphics { model = modelOf settings; };

  pair = igpuVendor: {
    gpus = {
      igpu = {
        vendor = igpuVendor;
        integrated = true;
        busId = "PCI:0:2:0";
      };
      dgpu = {
        vendor = "nvidia";
        busId = "PCI:1:0:0";
      };
    };
  };

  contractCases = [
    { }
    (pair "amd")
    ((pair "intel") // { prime = "sync"; })
    { guest = "qemu"; }
  ];

  tests = {

    testNothingDeclared = {
      expr = {
        codes = codes { };
        graphics = graphicsOf { };
      };
      expected = {
        codes = [ ];
        graphics = {
          enable = false;
          videoDrivers = [ ];
          nvidia = null;
          environment = { };
        };
      };
    };

    testBusIdFormat = {
      expr =
        map
          (
            busId:
            codes {
              gpus.g = {
                vendor = "amd";
                inherit busId;
              };
            }
          )
          [
            "PCI:1:0:0"
            "01:00.0"
            "PCI:01:00.0x"
          ];
      expected = [
        [ ]
        [ "hardware.gpu.busId.format" ]
        [ "hardware.gpu.busId.format" ]
      ];
    };

    # The integrated GPU's vendor picks the PRIME field.
    testPrimeField = {
      expr = map (vendor: (graphicsOf (pair vendor)).nvidia.prime) [
        "amd"
        "intel"
      ];
      expected = [
        {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          sync.enable = false;
          nvidiaBusId = "PCI:1:0:0";
          amdgpuBusId = "PCI:0:2:0";
        }
        {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          sync.enable = false;
          nvidiaBusId = "PCI:1:0:0";
          intelBusId = "PCI:0:2:0";
        }
      ];
    };

    testOffloadKeepsGpuNeutral = {
      expr =
        let
          graphics = graphicsOf (pair "intel");
        in
        {
          inherit (graphics) videoDrivers environment;
          finegrained = graphics.nvidia.powerManagement.finegrained;
        };
      expected = {
        videoDrivers = [ "nvidia" ];
        environment.ELECTRON_OZONE_PLATFORM_HINT = "auto";
        finegrained = true;
      };
    };

    testSyncMakesNvidiaPrimary = {
      expr =
        let
          graphics = graphicsOf ((pair "intel") // { prime = "sync"; });
        in
        {
          inherit (graphics) environment;
          sync = graphics.nvidia.prime.sync.enable;
          finegrained = graphics.nvidia.powerManagement.finegrained;
        };
      expected = {
        environment = {
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          LIBVA_DRIVER_NAME = "nvidia";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };
        sync = true;
        finegrained = false;
      };
    };

    testSingleVendorDrivers = {
      expr = map (vendor: (graphicsOf { gpus.g.vendor = vendor; }).videoDrivers) [
        "amd"
        "intel"
      ];
      expected = [
        [ "amdgpu" ]
        [ "modesetting" ]
      ];
    };

    testGpuChecks = {
      expr = map codes [
        { gpus.d.vendor = "nvidia"; }
        {
          gpus = {
            d.vendor = "nvidia";
            i = {
              vendor = "intel";
              integrated = true;
            };
          };
        }
        {
          gpus = {
            a = {
              vendor = "amd";
              integrated = true;
            };
            b = {
              vendor = "intel";
              integrated = true;
            };
          };
        }
        {
          gpus = {
            a.vendor = "nvidia";
            b.vendor = "nvidia";
          };
          prime = "none";
        }
      ];
      expected = [
        [ "hardware.gpu.prime.integrated.missing" ]
        [ "hardware.gpu.prime.busId.missing" ]
        [ "hardware.gpu.integrated.multiple" ]
        [ "hardware.gpu.nvidia.multiple" ]
      ];
    };

    testGuest = {
      expr = {
        qemu = codes { guest = "qemu"; };
        vbox = codes { guest = "vbox"; };
        services = hardware.guests.qemu.services;
      };
      expected = {
        qemu = [ ];
        vbox = [ "hardware.guest.unknown" ];
        services = [
          "qemuGuest"
          "spice-vdagentd"
          "fstrim"
        ];
      };
    };

    testAudioAndBluetooth = {
      expr = {
        off = {
          inherit (modelOf { }) audio bluetooth;
          audio_ = (hardware.audio { model = modelOf { }; }).active;
        };
        on =
          let
            model = modelOf {
              audio.enable = true;
              bluetooth.enable = true;
            };
          in
          {
            audio = (hardware.audio { inherit model; }).pipewire.alsa.support32Bit;
            bluetooth = (hardware.bluetooth { inherit model; }).state.directories;
          };
      };
      expected = {
        off = {
          audio = false;
          bluetooth = false;
          audio_ = false;
        };
        on = {
          audio = true;
          bluetooth = [ "/var/lib/bluetooth" ];
        };
      };
    };

    testModelContract = {
      expr = map (
        settings:
        let
          checked =
            (lib.evalModules {
              modules = [
                { options.model = lib.mkOption { type = hardware.types.model; }; }
                { model = modelOf settings; }
              ];
            }).config.model;
        in
        builtins.deepSeq checked true
      ) contractCases;
      expected = map (_: true) contractCases;
    };

  };
in
{
  perSystem =
    { pkgs, ... }:
    let
      failures = lib.runTests tests;
    in
    {
      checks.hardware-unit =
        if failures == [ ] then
          pkgs.runCommand "hardware-unit-tests" { } "touch $out"
        else
          throw "hardware unit tests failed:\n${lib.generators.toPretty { } failures}";
    };
}
