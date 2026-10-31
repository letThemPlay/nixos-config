_: {

  package = "bash";

  # NixOS enables bash already.
  system.programs = [ ];

  render =
    { aliases, ... }:
    {
      programs.bash = {
        enable = true;
        enableCompletion = true;
        historySize = 10000;
        shellAliases = aliases;
      };
    };

}
