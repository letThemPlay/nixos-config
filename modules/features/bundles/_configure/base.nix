{ pkgs, ... }:
{
  nixpkgs.config.allowUnfreePredicate = _: true;

  environment.systemPackages = [ pkgs.curl ];

  ltp = {
    nix.ld.enable = true;

    apps.install = [
      "eza"
      "zoxide"
    ];
  };
}
