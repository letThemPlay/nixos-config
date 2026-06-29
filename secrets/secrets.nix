let
  theseus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHKAIW/LBl1UYcJzwMvRpWy/DRqOE7IaKSgjDawvVTv";
  kelvin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDynItXS1ayKkq9UZ6Tw1jIB9Q1SK0lsuFsYofJY56Ni";
in
{
  "tailscale-authkey.age".publicKeys = [
    theseus
    kelvin
  ];
}
