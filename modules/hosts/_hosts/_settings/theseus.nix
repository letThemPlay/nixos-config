_: {
  ltp = {
    network = {
      profile = "laptop";
      dns.provider = "controld";
    };

    boot.secureBoot.enable = true;

    stylixOverrides = {
      cursorSize = 32;
      fontSize = {
        terminal = 14;
        applications = 13;
        desktop = 12;
      };
    };
  };
}
