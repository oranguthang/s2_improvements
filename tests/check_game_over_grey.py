"""Check that Game/Time Over uses the grey S1 Improvements tile colours."""
import json
from pathlib import Path
import sys

from test_stage1 import symbols


def main():
    repo = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(repo / 'tools'))
    from nemesis import decode, parse_header

    art = (repo / 'art/nemesis/Game and Time Over text.nem').read_bytes()
    header = parse_header(art)
    assert header.tiles == 34, header.tiles
    raw = decode(art)
    colours = {pixel for byte in raw for pixel in (byte >> 4, byte & 15)}
    assert colours == {0, 6, 7, 8, 9}, colours

    rom = (repo / 's2built.bin').read_bytes()
    address = symbols(repo / 's2.lst')['ArtNem_Game_Over']
    assert rom[address:address + len(art)] == art, 'Built ROM contains different art'
    print(json.dumps({
        'tiles': header.tiles,
        'grey_colour_indices': sorted(colours),
        'rom_offset': f'{address:06X}',
        'passed': True,
    }, indent=2))


if __name__ == '__main__':
    main()
