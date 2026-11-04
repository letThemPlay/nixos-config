{ config, ... }:
let
  hardware = config.ltp.features.hardware;
in
{
  flake.nixosModules.hardware =
    { config, lib, ... }:

    let
      inherit (lib)
        genAttrs
        mapAttrsToList
        mkIf
        mkMerge
        ;

      cfg = config.ltp.hardware;

      model = hardware.normalize cfg;

      validation = hardware.validate.all model;

      graphics = hardware.graphics { inherit model; };

      audio = hardware.audio { inherit model; };

      bluetooth = hardware.bluetooth { inherit model; };

      power = hardware.power { inherit model; };

      #
      # Every registered guest renders behind mkIf (guest == name), so
      # the module's shape does not depend on config.
      #
      renderGuest =
        name: guest:
        mkIf (model.guest.name == name) {
          services = genAttrs guest.services (_: {
            enable = true;
          });

          boot = {
            initrd.availableKernelModules = guest.initrdModules;
            inherit (guest) kernelParams;
          };
        };

      format = diagnostic: "ltp.hardware [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      config = mkMerge [

        # Published on every host, like the other features' facts.
        {
          ltp.hardware.facts = {
            inherit (model)
              audio
              bluetooth
              backlight
              powerProfiles
              ;

            battery = model.battery.active;

            batteryLevels = {
              low = model.battery.lowAt;
              critical = model.battery.criticalAt;
            };
          };
        }

        (mkIf cfg.enable (mkMerge [

          {
            assertions = errors;

            warnings = map format validation.warnings;
          }

          (mkIf audio.active {
            services.pulseaudio.enable = false;
            security.rtkit.enable = true;
            services.pipewire = audio.pipewire;
          })

          (mkIf bluetooth.active {
            hardware.bluetooth = {
              enable = true;
              inherit (bluetooth) powerOnBoot;
            };

            services.blueman.enable = true;

            # Reads only hardware options, so safe in persistence.state.
            ltp.storage.persistence.state.directories =
              mkIf config.ltp.storage.enable bluetooth.state.directories;
          })

          #
          # Rendering only runs on a valid model; invalid models stop at
          # the assertions above with a readable diagnostic.
          #
          (mkIf validation.ok (
            mkMerge (
              [
                (mkIf graphics.enable {
                  hardware.graphics = {
                    enable = true;
                    enable32Bit = true;
                  };

                  services.xserver.videoDrivers = graphics.videoDrivers;
                })

                (mkIf (graphics.nvidia != null) {
                  # The module system reads the attribute names of an mkIf's
                  # content even when it is false, so the content must be a set.
                  hardware.nvidia = lib.optionalAttrs (graphics.nvidia != null) (
                    graphics.nvidia
                    // {
                      package = config.boot.kernelPackages.nvidiaPackages.stable;
                    }
                  );
                })

                { environment.variables = graphics.environment; }

                (mkIf power.profiles.active { services.power-profiles-daemon.enable = true; })

                (mkIf power.battery.active { services.upower = power.battery.upower; })
              ]

              ++ mapAttrsToList renderGuest hardware.guests
            )
          ))

        ]))

      ];
    };
}
