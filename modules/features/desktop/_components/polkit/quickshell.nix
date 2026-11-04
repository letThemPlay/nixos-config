#
# The unified shell as the session's polkit agent: without an agent, nothing
# can show the password prompt that graphical admin actions wait on.
#
_: {
  security.polkit.enable = true;
}
