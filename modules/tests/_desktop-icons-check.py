# Every ligature the shell's icon vocabulary names must shape to one glyph of
# the icon font. Usage: _desktop-icons-check.py <Icons.qml> <font file>
import re
import sys

import uharfbuzz as hb

icons, font_file = sys.argv[1:]

font = hb.Font(hb.Face(hb.Blob.from_file_path(font_file)))


def is_one_glyph(name):
    text = hb.Buffer()
    text.add_str(name)
    text.guess_segment_properties()
    hb.shape(font, text)
    return len(text.glyph_infos) == 1


with open(icons) as source:
    names = re.findall(r'"[a-zA-Z]+": "([a-z0-9_]+)"', source.read())

# Without these, a broken parser or font would pass with nothing checked.
if len(names) < 20:
    sys.exit(f"found only {len(names)} icons in {icons}")

if is_one_glyph("definitely_not_an_icon"):
    sys.exit("a made-up icon name shapes to one glyph, so this check proves nothing")

missing = [name for name in names if not is_one_glyph(name)]

if missing:
    sys.exit(f"not in the icon font: {', '.join(missing)}")

print(f"{len(names)} icons found in the font")
