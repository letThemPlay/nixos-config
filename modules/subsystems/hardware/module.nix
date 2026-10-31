{ config, ... }:
let
  hardware = config.flake.subsystems.hardware;
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
      config = mkIf cfg.enable (mkMerge [

        {
          assertions = errors;

          warnings = map format validation.warnings;
        }

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
            ]

            ++ mapAttrsToList renderGuest hardware.guests
          )
        ))

      ]);
    };
}
