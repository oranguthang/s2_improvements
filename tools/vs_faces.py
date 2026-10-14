"""Make the 1-up monitor faces of Sonic and Knuckles as player 2 in 2P VS.

Usage: python tools/vs_faces.py [--check]

In 2P VS, player 2's HUD face is the Tails 1-up monitor icon (four tiles of
the monitor art). With Sonic or Knuckles as player 2 (FeatureKnuckles,
code/VSPlayers.asm), a pattern load request puts their face there instead:
the first four tiles (the face) of their life counter art, Nemesis-compressed
with inline codes only. Writes art/nemesis/VS face Sonic.nem and
VS face Knuckles.nem.
"""
import argparse, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import nemesis

FACE_TILES = 4
SOURCES = {
    'VS face Sonic.nem': 'Sonic lives counter.nem',
    'VS face Knuckles.nem': 'Knuckles lives counter.nem',
}


def generate():
    outputs = {}
    for name, source in SOURCES.items():
        raw = nemesis.decode((ROOT / 'art/nemesis' / source).read_bytes())[:FACE_TILES * 32]
        # an empty code table: every run is written inline
        packed = nemesis.encode_with_table(FACE_TILES.to_bytes(2, 'big') + b'\xff\x00', raw)
        assert nemesis.decode(packed) == raw
        outputs[ROOT / 'art/nemesis' / name] = packed
    return outputs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='only verify the files are up to date')
    args = ap.parse_args()
    outputs = generate()
    stale = [p for p, data in outputs.items() if not p.exists() or p.read_bytes() != data]
    if args.check:
        print('up to date' if not stale else 'stale: ' + ', '.join(str(p.relative_to(ROOT)) for p in stale))
        raise SystemExit(1 if stale else 0)
    for p, data in outputs.items():
        p.write_bytes(data)
        print('wrote', p.relative_to(ROOT))


if __name__ == '__main__':
    main()
