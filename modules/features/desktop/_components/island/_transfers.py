"""What's being copied or downloaded, a JSON list a line, for the shell's island.

Neither Firefox nor yazi says, so this looks. How far along a copying program is shows in
the file it has open to read and, for some, the one it's writing. A browser's unfinished
file only says how big it has got, so a download has no percentage. A line is written even
when nothing has changed, so this ends with the shell rather than outliving it.
"""

import json
import os
import stat
import time

INTERVAL = 2

# As /proc/<pid>/comm names them. Others read files for reasons that aren't copying.
COPIERS = frozenset(["cp", "mv", "rsync", "dd", "tar", "yazi"])

# These can hand the kernel gigabytes at a time, and their read position only moves once
# it's finished, so what they're writing says more. Not tar, which writes an archive.
WRITE_THROUGH = frozenset(["cp", "mv", "yazi"])

# Smaller files are finished before this could say anything useful.
SMALLEST = 16 * 1024 * 1024

UNFINISHED = (".part", ".crdownload")

# A download stalled for longer than this has probably been paused or abandoned.
STALLED_AFTER = 30

# How much of each new rate to take, so one slow moment doesn't swing the estimate.
SMOOTHING = 0.3


def open_files(pid):
    """A process's regular files: those it's reading as (path, position, size), and the
    sizes of those it's writing."""
    reading = []
    writing = []

    for fd in os.scandir(f"/proc/{pid}/fd"):
        try:
            path = os.readlink(fd.path)
            info = os.stat(fd.path)

            if not stat.S_ISREG(info.st_mode):
                continue

            with open(f"/proc/{pid}/fdinfo/{fd.name}") as details:
                fields = dict(line.split(":", 1) for line in details if ":" in line)
        except OSError:
            # One closing as this looks at it doesn't say anything about the others.
            continue

        if int(fields["flags"], 8) & os.O_ACCMODE == os.O_RDONLY:
            reading.append((path, int(fields["pos"]), info.st_size))
        else:
            writing.append(info.st_size)

    return reading, writing


def copying():
    """Each large file a copier has open for reading: {path: (amount copied, size)}."""
    found = {}

    for entry in os.scandir("/proc"):
        if not entry.name.isdigit():
            continue

        try:
            with open(f"/proc/{entry.name}/comm") as comm:
                name = comm.read().strip()

            if name not in COPIERS:
                continue

            reading, writing = open_files(entry.name)
        except OSError:
            # Processes come and go, and others' can't be read.
            continue

        for path, position, size in reading:
            if size < SMALLEST:
                continue

            done = position

            # The biggest that could be this copy, as a log file won't be it.
            if name in WRITE_THROUGH:
                done = max([position] + [written for written in writing if written <= size])

            found[path] = (max(done, found.get(path, (0, 0))[0]), size)

    return found


def download_name(directory, entry):
    """A file's own name. Firefox can scramble the unfinished file's name, as JKzMn.zip.part,
    and hold the real one as an empty file of the same type alongside it. The newest such
    file is the likeliest, and at worst this shows the wrong name."""
    name = entry.name.rsplit(".", 1)[0]
    extension = os.path.splitext(name)[1]
    newest = None

    if not extension or os.path.exists(os.path.join(directory, name)):
        return name

    for other in os.scandir(directory):
        if other.name.endswith(extension) and other.is_file():
            info = other.stat()
            if info.st_size == 0 and (newest is None or info.st_mtime > newest[0]):
                newest = (info.st_mtime, other.name)

    return newest[1] if newest else name


def downloading(directory):
    """Each unfinished file: {path: (size, name)}."""
    found = {}

    try:
        for entry in os.scandir(directory):
            if entry.name.endswith(UNFINISHED) and entry.is_file():
                found[entry.path] = (entry.stat().st_size, download_name(directory, entry))
    except OSError:
        pass

    return found


class Tracked:
    """A file seen moving. Nothing's reported until it has, so an idle program's open
    files and a download left behind by an earlier run never appear."""

    def __init__(self, amount, now):
        self.amount = amount
        self.moved_at = None
        self.seen_at = now
        self.rate = 0

    def update(self, amount, now):
        if amount > self.amount:
            rate = (amount - self.amount) / (now - self.seen_at)
            self.rate = rate if self.rate == 0 else self.rate + (rate - self.rate) * SMOOTHING
            self.moved_at = now

        self.amount = amount
        self.seen_at = now


def report(tracked, kind, path, name, total):
    remaining = (total - tracked.amount) / tracked.rate if total and tracked.rate else -1

    return {
        "id": path,
        "kind": kind,
        "name": name,
        "done": tracked.amount,
        "total": total,
        "rate": round(tracked.rate),
        "remaining": round(remaining),
    }


def main():
    home = os.path.expanduser("~")
    directory = os.environ.get("XDG_DOWNLOAD_DIR", os.path.join(home, "Downloads"))
    tracked = {}

    while True:
        now = time.monotonic()
        copies = copying()
        downloads = downloading(directory)
        current = []

        for path, (position, size) in copies.items():
            seen = tracked.setdefault(path, Tracked(position, now))
            seen.update(position, now)

            if seen.moved_at == now:
                current.append(report(seen, "copy", path, os.path.basename(path), size))

        for path, (size, name) in downloads.items():
            seen = tracked.setdefault(path, Tracked(size, now))
            seen.update(size, now)

            if seen.moved_at is not None and now - seen.moved_at < STALLED_AFTER:
                current.append(report(seen, "download", path, name, 0))

        tracked = {path: seen for path, seen in tracked.items() if path in copies or path in downloads}

        print(json.dumps(current), flush=True)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
