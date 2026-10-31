"""Recolour Sonic 2's Game/Time Over art using S1 Improvements' grey indices."""
import argparse
from pathlib import Path

from nemesis import decode, encode_with_table, parse_header

COLOUR_MAP = {
    0: 0,  # transparency
    2: 9,  # dark blue outline -> dark grey
    3: 8,  # blue outline -> grey
    4: 7,  # light blue outline -> light grey
    5: 6,  # pale blue edge -> white
    6: 6,  # white lettering stays white
}


def pixels(raw):
    return [pixel for byte in raw for pixel in (byte >> 4, byte & 15)]


def pack(data):
    return bytes(high << 4 | low for high, low in zip(data[::2], data[1::2]))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    original = args.input.read_bytes()
    assert parse_header(original).tiles == 34
    source = pixels(decode(original))
    assert set(source) == set(COLOUR_MAP), set(source)
    recoloured = [COLOUR_MAP[pixel] for pixel in source]
    assert all((before == 0) == (after == 0) for before, after in zip(source, recoloured))
    raw = pack(recoloured)
    encoded = encode_with_table(original, raw)
    assert decode(encoded) == raw
    args.output.write_bytes(encoded)
    print(f'Recoloured {len(source)} pixels in 34 original S2 tiles; '
          f'colour indices: {sorted(set(recoloured))}')


if __name__ == '__main__':
    main()
