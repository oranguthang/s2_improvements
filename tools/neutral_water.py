"""Keep ARZ's water surface independent of character palette cycles.
The source art is retained; only its blue ramp becomes the fixed grey ramp.
Run with --check to verify the generated Nemesis resource.
"""
import argparse
from pathlib import Path
from nemesis import decode, encode_with_table

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/nemesis/Top of water in ARZ.nem'
OUTPUT = ROOT / 'art/nemesis/Top of water in ARZ neutral.nem'
COLOURS = {2: 9, 3: 8, 4: 7, 5: 6}

def generate():
    source = SOURCE.read_bytes()
    original = decode(source)
    lookup = tuple(COLOURS.get(i, i) for i in range(16))
    result = bytes(lookup[b >> 4] << 4 | lookup[b & 15] for b in original)
    assert all((a >> 4 == 0) == (b >> 4 == 0) and (a & 15 == 0) == (b & 15 == 0)
               for a, b in zip(original, result))
    assert not any(n in COLOURS for b in result for n in (b >> 4, b & 15))
    packed = encode_with_table(source, result)
    assert decode(packed) == result
    return packed

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    data = generate()
    if args.check:
        assert OUTPUT.read_bytes() == data, 'Regenerate the neutral water art'
        print('ARZ neutral water is up to date')
    else:
        OUTPUT.write_bytes(data)
        print('wrote', OUTPUT.relative_to(ROOT))

if __name__ == '__main__':
    main()
