"""Make the 1-up monitor faces of Sonic and Knuckles as player 2 in 2P VS.

Usage: python tools/vs_faces.py [--check]

In 2P VS, player 2's HUD face is the Tails 1-up monitor icon (four tiles of
the monitor art). With Sonic or Knuckles as player 2 (FeatureKnuckles,
code/VSPlayers.asm), a pattern load request puts their face there instead:
the first four tiles (the face) of their life counter art, Nemesis-compressed
with inline codes only. Writes art/nemesis/VS face Sonic.nem and
VS face Knuckles.nem.

A game of Sonic against Knuckles keeps Sonic's colours 2-5 and moves
Knuckles' to other slots (tools/knuckles_vs.py, SONIC_GAME_REMAP), so his
faces there come from copies with those colours: VS face Knuckles Sonic.nem,
Knuckles lives counter Sonic.nem (the face tiles; the name keeps its colours)
and art/uncompressed/Signpost Knuckles Sonic.bin (the tiles that differ from
Sonic's signpost).
"""
import argparse, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import nemesis
from knuckles_vs import SONIC_GAME_REMAP

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
    remap = bytes(SONIC_GAME_REMAP.get(b >> 4, b >> 4) << 4 | SONIC_GAME_REMAP.get(b & 15, b & 15) for b in range(256))
    face = nemesis.decode(outputs[ROOT / 'art/nemesis/VS face Knuckles.nem']).translate(remap)
    outputs[ROOT / 'art/nemesis/VS face Knuckles Sonic.nem'] = inline(face)
    counter = nemesis.decode((ROOT / 'art/nemesis/Knuckles lives counter.nem').read_bytes())
    counter = counter[:FACE_TILES * 32].translate(remap) + counter[FACE_TILES * 32:]
    outputs[ROOT / 'art/nemesis/Knuckles lives counter Sonic.nem'] = inline(counter)
    base = (ROOT / 'art/uncompressed/Signpost.bin').read_bytes()
    knuckles = (ROOT / 'art/uncompressed/Signpost Knuckles.bin').read_bytes()
    tiles = [knuckles[i:i + 32] for i in range(0, len(knuckles), 32)]
    outputs[ROOT / 'art/uncompressed/Signpost Knuckles Sonic.bin'] = b''.join(
        t if t == base[i * 32:i * 32 + 32] else t.translate(remap) for i, t in enumerate(tiles))
    return outputs


def inline(raw):
    """Nemesis with an empty code table: every run is written inline."""
    packed = nemesis.encode_with_table((len(raw) // 32).to_bytes(2, 'big') + b'\xff\x00', raw)
    assert nemesis.decode(packed) == raw
    return packed


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
