#
# Public keys by name. secrets.nix (the agenix rules) encrypts each
# secret for a list of these; the secrets subsystem checks that a host
# using a secret is among its recipients.
#
# Hosts: the host's /etc/ssh/ssh_host_ed25519_key.pub.
#
{
  hosts = {
    theseus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHKAIW/LBl1UYcJzwMvRpWy/DRqOE7IaKSgjDawvVTv";
  };

  users = {
    kelvin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDynItXS1ayKkq9UZ6Tw1jIB9Q1SK0lsuFsYofJY56Ni";
  };
}
