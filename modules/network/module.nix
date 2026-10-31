{ config, ... }:
let
  network = config.flake.library.network;
in
{
  flake.nixosModules.network =
    { config, lib, ... }:

    let
      inherit (lib)
        mapAttrsToList
        mkIf
        mkMerge
        ;

      cfg = config.ltp.network;

      model = network.normalize cfg;

      validation = network.validate.all model;

      #
      # Every registered backend renders behind mkIf (model.backend ==
      # name), so the module's shape does not depend on config.
      # Transforms return plain data; conditions stay inside mkIf here.
      #
      renderBackend =
        name: backend:
        mkIf (model.backend == name) {
          networking.useNetworkd = true;

          systemd.network.networks = (backend.links { inherit model; }).networks;
        };

      #
      # How each wireless backend's settings reach NixOS. Every key of
      # network.wireless needs an entry here.
      #
      wirelessOptions = {
        iwd = settings: {
          networking.wireless.iwd = {
            enable = true;

            inherit settings;
          };
        };
      };

      renderWireless =
        name: backend:
        let
          wireless = backend { inherit model; };
        in
        mkIf (wireless.active && model.wireless.backend == name) (mkMerge [
          (wirelessOptions.${name} wireless.settings)

          {
            #
            # The condition reads only network options, never storage
            # ones, so it is safe inside persistence.state.
            #
            ltp.storage.persistence.state = mkIf config.ltp.storage.enable wireless.state;
          }
        ]);

      format = diagnostic: "ltp.network [${diagnostic.code}]: ${diagnostic.message}";

      errors = map (diagnostic: {
        assertion = false;
        message = format diagnostic;
      }) validation.errors;
    in
    {
      config = mkMerge [

        # Not part of the network model; kept as before.
        { networking.firewall.enable = false; }

        (mkIf cfg.enable (mkMerge [

          {
            assertions = errors;

            warnings = map format validation.warnings;

            networking = {
              dhcpcd.enable = false;
              useDHCP = false;
            };
          }

          #
          # Rendering only runs on a valid model; invalid models stop at
          # the assertions above with a readable diagnostic.
          #
          (mkIf validation.ok (
            mkMerge (
              [
                {
                  services.resolved = {
                    enable = true;

                    settings = network.resolved { inherit model; };
                  };
                }
              ]

              ++ mapAttrsToList renderBackend network.backends

              ++ mapAttrsToList renderWireless network.wireless
            )
          ))

        ]))

      ];
    };
}
