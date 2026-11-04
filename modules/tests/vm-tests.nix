{ flake-parts-lib, lib, ... }:
{
  #
  # Tests that boot VMs, kept out of `checks` because they take minutes. legacyPackages
  # doesn't merge an attribute across files, so each test sets its own vmTests entry
  # and they're published here together:
  #
  #   nix build .#vmTests.<name>
  #
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.vmTests = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.package;
      default = { };
      description = "NixOS VM tests by name.";
    };
  };

  config.perSystem =
    { config, ... }:
    {
      legacyPackages.vmTests = config.vmTests;
    };
}
