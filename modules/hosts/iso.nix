{
  inputs,
  ...
}:
{
  flake = _: {
    nixosConfigurations = {
      iso = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ pkgs, ... }: {
            environment.systemPackages = with pkgs; [
              git
              htop
              tmux
            ];

            nix = {
              extraOptions = "experimental-features = nix-command flakes pipe-operators";
            };

            networking = {
              firewall.enable = false;
              dhcpcd.enable = false;
              useDHCP = false;
              useNetworkd = true;
            };

            services.resolved = {
              enable = true;
              settings.Resolve = {
                DNSOverTLS = "yes";
                FallbackDNS = [ "8.8.8.8" ];
              };
            };
          })
        ];
      };
    };
  };
}
