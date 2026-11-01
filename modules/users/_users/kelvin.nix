{
  fullName = "Kelvin";
  email = "kelvin.d.morris@gmail.com";
  admin = true;
  bundles = [
    "flashgbx"
  ];
  extraPackages = [
    "firefox"
    "vlc"
  ];
  theme = "catppuccin";
  shell = "zsh";

  # Public key in gpg/kelvin/; the secret subkeys are on a smartcard.
  gpg = {
    signingKey = "0x5D0149C121F819A6";
    smartcard = true;
  };
}
