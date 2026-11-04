{ config, ... }:
let
  inherit (config.ltp.features) desktop;
in
{
  perSystem =
    { pkgs, ... }:
    let
      helper = desktop.wifiHelper pkgs;

      passphrase = "correct-horse-battery";

      accessPoint =
        name: settings:
        let
          file = pkgs.writeText "hostapd-${name}.conf" settings;
        in
        {
          after = [ "sys-subsystem-net-devices-${name}.device" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.ExecStart = "${pkgs.hostapd}/bin/hostapd ${file}";
        };
    in
    {
      #
      # The Wi-Fi panel's helper against a real iwd, on virtual radios. Not part
      # of `nix flake check`:
      #
      #   nix build .#vmTests.wifi
      #
      vmTests.wifi = pkgs.testers.runNixOSTest {
        name = "wifi-helper";

        nodes.machine = {
          boot = {
            kernelModules = [ "mac80211_hwsim" ];
            extraModprobeConfig = "options mac80211_hwsim radios=3";
          };

          networking = {
            usePredictableInterfaceNames = false;
            wireless.iwd = {
              enable = true;
              settings.DriverQuirks.DefaultInterface = "*";
            };
          };

          # The other two radios belong to the access points.
          systemd.services = {
            iwd.serviceConfig.ExecStart = [
              ""
              "${pkgs.iwd}/libexec/iwd --phys phy0"
            ];

            ap-psk = accessPoint "wlan1" ''
              interface=wlan1
              ssid=test-psk
              hw_mode=g
              channel=1
              wpa=2
              wpa_key_mgmt=WPA-PSK
              rsn_pairwise=CCMP
              wpa_passphrase=${passphrase}
            '';

            ap-open = accessPoint "wlan2" ''
              interface=wlan2
              ssid=test-open
              hw_mode=g
              channel=6
            '';
          };

          users.users = {
            member = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };

            outsider.isNormalUser = true;
          };
        };

        testScript = ''
          import json


          def helper(arguments, user="member", stdin="/dev/null"):
              status, out = machine.execute(
                  f"su -s /bin/sh {user} -c '${helper} {arguments} < {stdin}'"
              )
              return status, json.loads(out)


          def network(name):
              _, state = helper("list")
              return next(n for n in state["networks"] if n["name"] == name)


          def both_seen(_):
              helper("scan")
              _, state = helper("list")
              return {"test-psk", "test-open"} <= {n["name"] for n in state["networks"]}


          def connected(name):
              return lambda _: network(name)["connected"]


          machine.wait_for_unit("iwd.service")
          machine.wait_for_unit("ap-psk.service")
          machine.wait_for_unit("ap-open.service")

          # The passphrases are in files, so the shell running this holds neither.
          machine.succeed("echo wrong-passphrase-here > /tmp/wrong; chmod 644 /tmp/wrong")
          machine.succeed("echo short > /tmp/short; chmod 644 /tmp/short")
          machine.succeed("echo '${passphrase}' > /tmp/right; chmod 644 /tmp/right")

          with subtest("list and scan find both networks"):
              retry(both_seen)
              _, state = helper("list")
              assert state["ok"] and state["present"] and state["powered"]
              security = {n["name"]: n["security"] for n in state["networks"]}
              assert security["test-psk"] == "psk", security
              assert security["test-open"] == "open", security

          psk = network("test-psk")["path"]
          opened = network("test-open")["path"]

          with subtest("a network needing a passphrase says so"):
              status, reply = helper(f"connect {psk}")
              assert status != 0 and reply["error"] == "needs-passphrase", reply

          with subtest("a passphrase iwd can't accept is turned down"):
              status, reply = helper(f"connect {psk}", stdin="/tmp/short")
              assert status != 0 and reply["error"] == "wrong-passphrase", reply

          with subtest("a wrong passphrase is reported as one"):
              status, reply = helper(f"connect {psk}", stdin="/tmp/wrong")
              assert status != 0 and reply["error"] == "wrong-passphrase", reply
              assert not network("test-psk")["known"]

          with subtest("the right passphrase connects, off the process table"):
              machine.succeed(
                  "(while :; do ps -eo args >> /tmp/processes; sleep 0.05; done) "
                  ">/dev/null 2>&1 & echo $! > /tmp/watcher"
              )
              status, reply = helper(f"connect {psk}", stdin="/tmp/right")
              machine.succeed("kill $(cat /tmp/watcher)")
              assert status == 0 and reply["ok"], reply
              retry(connected("test-psk"))
              state = network("test-psk")
              assert state["known"] and state["signal"] > 0, state
              machine.succeed("test -s /tmp/processes")
              machine.fail("grep -F -f /tmp/right /tmp/processes")
              machine.fail("journalctl -b --no-pager | grep -F -f /tmp/right")

          with subtest("the connected network sorts first"):
              _, state = helper("list")
              assert state["networks"][0]["name"] == "test-psk", state

          with subtest("disconnect leaves it known"):
              status, reply = helper("disconnect")
              assert status == 0, reply
              retry(lambda _: not network("test-psk")["connected"])
              assert network("test-psk")["known"]

          with subtest("a known network asks for nothing"):
              status, reply = helper(f"connect {psk}")
              assert status == 0, reply
              retry(connected("test-psk"))
              helper("disconnect")

          with subtest("an open network needs no passphrase"):
              status, reply = helper(f"connect {opened}")
              assert status == 0, reply
              retry(connected("test-open"))
              helper("disconnect")

          with subtest("forget removes it"):
              status, reply = helper(f"forget {psk}")
              assert status == 0, reply
              retry(lambda _: not network("test-psk")["known"])
              status, reply = helper(f"forget {psk}")
              assert status != 0 and reply["error"] == "not-known", reply

          with subtest("the radio turns off and on"):
              status, reply = helper("power off")
              assert status == 0, reply
              retry(lambda _: not helper("list")[1]["powered"])
              _, state = helper("list")
              assert state["present"] and state["networks"] == [], state
              status, reply = helper("scan")
              assert status != 0 and reply["error"] == "no-station", reply
              status, reply = helper("power on")
              assert status == 0, reply
              retry(lambda _: helper("list")[1]["powered"])

          with subtest("a user outside wheel is told so"):
              status, reply = helper("list", user="outsider")
              assert status != 0 and reply["error"] == "not-allowed", reply

          with subtest("misuse is reported"):
              status, reply = helper("power sideways")
              assert status != 0 and reply["error"] == "usage", reply

          # Masked, as D-Bus would otherwise just start it again. An error or no
          # device both reach the panel as something to say, rather than a crash.
          with subtest("an iwd that can't run still answers"):
              machine.succeed("systemctl mask --runtime --now iwd.service")
              _, reply = helper("list")
              assert not reply["ok"] or not reply["present"], reply
        '';
      };
    };
}
