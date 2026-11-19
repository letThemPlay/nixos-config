{ config, ... }:
let
  network = config.ltp.features.network;
in
{
  flake.nixosModules.network =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        attrValues
        escapeShellArgs
        filter
        filterAttrs
        mapAttrs
        mapAttrs'
        mapAttrsToList
        mkIf
        mkMerge
        nameValuePair
        optional
        removeSuffix
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

          # The backend's UI where the host asks for it.
          {
            environment.systemPackages = lib.optional (
              model.wireless.ui && wireless.ui != null
            ) pkgs.${wireless.ui};
          }

          {
            #
            # The condition reads only network options, never storage
            # ones, so it is safe inside persistence.state.
            #
            ltp.storage.persistence.state = mkIf config.ltp.storage.enable wireless.state;
          }
        ]);

      secretPath = name: config.ltp.secrets.facts.paths.${name};

      #
      # How each tunnel backend's daemon reaches NixOS. Every key of
      # network.tunnels needs an entry here.
      #
      tunnelOptions = {
        tailscale = adapter: {
          services.tailscale = {
            enable = true;

            inherit (adapter.daemon) interfaceName useRoutingFeatures;
          };
        };

        wireguard = adapter: {
          systemd.network = {
            inherit (adapter) netdevs networks;
          };
        };
      };

      #
      # The unit that holds one tunnel up while it is active. Of two
      # conflicting units, the one sorting later is ordered after the
      # other: any ordering makes systemd stop the old tunnel before it
      # starts the new one, and one direction avoids a cycle.
      #
      tunnelUnit =
        adapter: tunnel: commands:
        let
          online = optional adapter.online "network-online.target";

          requires = commands.requires or [ ];
        in
        {
          description = "Tunnel ${tunnel.label}";

          after = adapter.after ++ online ++ requires ++ filter (unit: unit < tunnel.unit) tunnel.conflicts;
          wants = adapter.after ++ online;

          inherit requires;

          inherit (tunnel) conflicts;

          wantedBy = optional tunnel.autostart "multi-user.target";

          path = map (name: pkgs.${name}) adapter.packages;

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            TimeoutStartSec = 90;
          };

          script = escapeShellArgs commands.start;

          preStop = escapeShellArgs commands.stop;
        };

      renderTunnels =
        name: backend:
        let
          adapter = backend { inherit model secretPath; };
        in
        mkIf adapter.active (mkMerge [
          (tunnelOptions.${name} adapter)

          {
            ltp.secrets.files = adapter.secrets;

            systemd.services = mapAttrs' (
              tunnelName: commands:
              let
                tunnel = model.tunnels.${tunnelName};
              in
              nameValuePair (removeSuffix ".service" tunnel.unit) (tunnelUnit adapter tunnel commands)
            ) adapter.commands;

            # Reads only network options, like the wireless state.
            ltp.storage.persistence.state = mkIf config.ltp.storage.enable adapter.state;
          }
        ]);

      tunnelUnits = map (tunnel: tunnel.unit) (attrValues model.tunnels);

      #
      # Users at the seat may switch tunnels: start and stop exactly the
      # tunnel units, nothing else.
      #
      tunnelPolkitRule = ''
        // ltp.network: users at the seat switch the tunnels.
        polkit.addRule(function (action, subject) {
          var units = ${builtins.toJSON tunnelUnits};
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              units.indexOf(action.lookup("unit")) >= 0 &&
              (action.lookup("verb") == "start" || action.lookup("verb") == "stop") &&
              subject.local && subject.active && subject.isInGroup("users")) {
            return polkit.Result.YES;
          }
        });
      '';

      # The wireless backend in use, when it runs.
      wirelessBackend =
        let
          backend = network.wireless.${model.wireless.backend} or null;
        in
        if backend == null then null else backend { inherit model; };

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

        #
        # Published on every host, like the other features' facts. The
        # wireless UI and the tunnels describe what is rendered, so a
        # disabled feature or an invalid model offers neither.
        #
        {
          ltp.network.facts =
            let
              rendered = cfg.enable && validation.ok;
            in
            {
              wireless = if cfg.enable then network.query.wirelessBackend model else null;

              wirelessUi =
                if rendered && model.wireless.ui && wirelessBackend != null && wirelessBackend.active then
                  wirelessBackend.ui
                else
                  null;

              tunnels =
                if rendered then
                  mapAttrs (_: tunnel: {
                    inherit (tunnel)
                      label
                      backend
                      unit
                      routesAll
                      ;
                  }) (filterAttrs (_: tunnel: tunnel.known) model.tunnels)
                else
                  { };
            };
        }

        (mkIf cfg.enable (mkMerge [

          {
            assertions = errors;

            warnings = map format validation.warnings;

            networking = {
              dhcpcd.enable = false;
              useDHCP = false;
            };

            systemd.network.wait-online.enable = cfg.waitOnline;
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

              ++ mapAttrsToList renderTunnels network.tunnels

              ++ [
                (mkIf (tunnelUnits != [ ]) {
                  security.polkit.extraConfig = tunnelPolkitRule;
                })
              ]
            )
          ))

        ]))

      ];
    };
}
