"""Generate Casino Night's transparent portrait layers from its slot art."""
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "art/uncompressed"
# Stock Casino Night palette line 1 (the second VDP palette line).
# The layer covers only pixels that use the main character's changing colours.
SONIC = {2: 1, 3: 15, 4: 15, 5: 14}
KNUCKLES = {2: 11, 3: 2, 4: 13, 5: 3}
JACKPOT = {2: 15, 5: 14}


def generate():
    symbols = (ART / "Slot pictures.bin").read_bytes()
    knuckles = (ART / "Slot picture Knuckles.bin").read_bytes()
    for name, source, lookup in (
        ("Sonic portrait", symbols[:512], SONIC),
        ("Knuckles portrait", knuckles, KNUCKLES),
        ("Jackpot", symbols[3*512:4*512], JACKPOT),
    ):
        assert len(source) == 512
        layer = bytes(lookup.get(byte >> 4, 0) << 4 | lookup.get(byte & 15, 0) for byte in source)
        yield ART / f"CNZ {name} layer.bin", layer


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    for path, data in generate():
        if args.check:
            assert path.read_bytes() == data, path
        else:
            path.write_bytes(data)
