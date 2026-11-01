_: {
  #
  # Sets up the users' OpenPGP keys on this host: gpg, gpg-agent with
  # pinentry, SSH through the agent, smartcard rules and git signing.
  # See ltp.identity.gpg and each user's gpg settings.
  #
  flake.nixosModules.gpg = _: {
    ltp.identity.gpg.enable = true;
  };
}
