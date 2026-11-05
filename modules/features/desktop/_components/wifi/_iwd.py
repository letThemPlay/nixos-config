# What the shell's Wi-Fi panel asks of iwd, over its D-Bus API. Every command
# prints one JSON line.
#
# iwctl only takes a passphrase as an argument, where any local process can read
# it from /proc. Here it arrives on stdin and goes to iwd through an agent, which
# lives for one connect and only answers for the network being joined.
import asyncio
import json
import sys

from dbus_fast import BusType, DBusError, Message, MessageType, Variant
from dbus_fast.aio import MessageBus
from dbus_fast.service import ServiceInterface, method

IWD = "net.connman.iwd"
ROOT = "/net/connman/iwd"
AGENT_PATH = "/ltp/wifi/agent"

ERRORS = {
    "org.freedesktop.DBus.Error.AccessDenied": "not-allowed",
    "org.freedesktop.DBus.Error.ServiceUnknown": "unavailable",
    "org.freedesktop.DBus.Error.NameHasNoOwner": "unavailable",
    "net.connman.iwd.Aborted": "aborted",
    "net.connman.iwd.Busy": "busy",
    "net.connman.iwd.InProgress": "busy",
    "net.connman.iwd.NotConnected": "not-connected",
}


class Failure(Exception):
    def __init__(self, code):
        super().__init__(code)
        self.code = code


class Agent(ServiceInterface):
    def __init__(self, network, passphrase):
        super().__init__(f"{IWD}.Agent")
        self.network = network
        self.passphrase = passphrase
        self.asked = False

    @method()
    def Release(self):
        pass

    @method()
    def Cancel(self, reason: "s"):
        pass

    @method()
    def RequestPassphrase(self, network: "o") -> "s":
        self.asked = True

        if network != self.network or not self.passphrase:
            raise DBusError(f"{IWD}.Agent.Error.Canceled", "No passphrase")

        return self.passphrase


async def call(bus, path, interface, member, signature="", body=None):
    reply = await bus.call(
        Message(
            destination=IWD,
            path=path,
            interface=interface,
            member=member,
            signature=signature,
            body=body or [],
        )
    )

    if reply.message_type == MessageType.ERROR:
        raise Failure(ERRORS.get(reply.error_name, "failed"))

    return reply.body


async def objects(bus):
    body = await call(
        bus, "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"
    )

    return {
        path: {
            interface: {key: value.value for key, value in values.items()}
            for interface, values in interfaces.items()
        }
        for path, interfaces in body[0].items()
    }


def find(known, interface):
    return next(
        (path for path in sorted(known) if interface in known[path]),
        None,
    )


def station(known):
    path = find(known, f"{IWD}.Station")

    if path is None:
        raise Failure("no-station")

    return path


# -90 dBm is barely usable and -50 dBm is as good as it gets, as the bar counts.
def strength(signal):
    return max(0, min(100, (signal // 100 + 90) * 100 // 40))


async def list_networks(bus):
    known = await objects(bus)
    device = find(known, f"{IWD}.Device")
    path = find(known, f"{IWD}.Station")

    device_values = known[device][f"{IWD}.Device"] if device else {}

    result = {
        "present": device is not None,
        "powered": device_values.get("Powered", False),
        "scanning": False,
        "networks": [],
    }

    if path is None:
        return result

    result["scanning"] = known[path][f"{IWD}.Station"].get("Scanning", False)

    ordered = await call(bus, path, f"{IWD}.Station", "GetOrderedNetworks")

    for network, signal in ordered[0]:
        values = known[network][f"{IWD}.Network"]

        result["networks"].append(
            {
                "path": network,
                "name": values["Name"],
                "security": values["Type"],
                "signal": strength(signal),
                "connected": values.get("Connected", False),
                "known": "KnownNetwork" in values,
            }
        )

    result["networks"].sort(
        key=lambda n: (not n["connected"], not n["known"], -n["signal"])
    )

    return result


async def scan(bus):
    try:
        await call(bus, station(await objects(bus)), f"{IWD}.Station", "Scan")
    except Failure as failure:
        if failure.code != "busy":
            raise


async def connect(bus, network):
    passphrase = sys.stdin.readline().rstrip("\n")

    # What iwd accepts; anything else it would only fail later and vaguely.
    if passphrase and not 8 <= len(passphrase) <= 64:
        raise Failure("wrong-passphrase")

    agent = Agent(network, passphrase)
    bus.export(AGENT_PATH, agent)

    await call(
        bus,
        ROOT,
        f"{IWD}.AgentManager",
        "RegisterAgent",
        "o",
        [AGENT_PATH],
    )

    try:
        await call(bus, network, f"{IWD}.Network", "Connect")
    except Failure as failure:
        if agent.asked and not passphrase:
            raise Failure("needs-passphrase") from failure
        if agent.asked and failure.code == "failed":
            raise Failure("wrong-passphrase") from failure
        raise


async def disconnect(bus):
    path = station(await objects(bus))
    await call(bus, path, f"{IWD}.Station", "Disconnect")


async def forget(bus, network):
    values = (await objects(bus)).get(network, {}).get(f"{IWD}.Network", {})

    if "KnownNetwork" not in values:
        raise Failure("not-known")

    await call(bus, values["KnownNetwork"], f"{IWD}.KnownNetwork", "Forget")


async def power(bus, state):
    device = find(await objects(bus), f"{IWD}.Device")

    if device is None:
        raise Failure("no-device")

    await call(
        bus,
        device,
        "org.freedesktop.DBus.Properties",
        "Set",
        "ssv",
        [f"{IWD}.Device", "Powered", Variant("b", state == "on")],
    )


async def run(arguments):
    command = arguments[0] if arguments else ""
    rest = arguments[1:]

    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()

    try:
        if command == "list" and not rest:
            return await list_networks(bus)
        if command == "scan" and not rest:
            await scan(bus)
        elif command == "connect" and len(rest) == 1:
            await connect(bus, rest[0])
        elif command == "disconnect" and not rest:
            await disconnect(bus)
        elif command == "forget" and len(rest) == 1:
            await forget(bus, rest[0])
        elif command == "power" and rest in (["on"], ["off"]):
            await power(bus, rest[0])
        else:
            raise Failure("usage")

        return {}
    finally:
        bus.disconnect()


def main():
    try:
        result = {"ok": True, **asyncio.run(run(sys.argv[1:]))}
    except Failure as failure:
        result = {"ok": False, "error": failure.code}

    print(json.dumps(result))
    sys.exit(0 if result["ok"] else 1)


main()
