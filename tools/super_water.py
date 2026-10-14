"""Make the underwater palette cycles of Super Tails and Super Knuckles.

Usage: python tools/super_water.py [--check]

Below the water line the game shows Underwater_palette, so a Super form's
palette cycle has to write tinted colours there too (as Super Sonic does with
CPZWater/ARZWater SS transformation.bin, and Sonic 1 with its own LZ and SBZ3
cycles). Sonic 2's underwater palettes are drawn by hand rather than made
with one formula, so each zone's tint is taken from its own examples: every
colour moves like the nearest colour in the zone's pairs of dry and
underwater colours (Sonic and Tails' first palette line, Knuckles' colours,
and Super Sonic's transformation where the zone has one).

Writes art/palettes/Super Knuckles cycle <zone> underwater.bin (colours 2, 3
and 5 per frame, as Super Knuckles cycle.bin) and Super Tails <zone>
underwater.bin (colours 11, 15 and 14 and a pad word per frame, as
PalCycle_SuperTails_Colours in code/SuperTails.asm) for CPZ, ARZ and HPZ.
"""
import argparse, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAL = ROOT / 'art' / 'palettes'
ZONES = ('CPZ', 'ARZ', 'HPZ')
SUPER_SONIC = {'CPZ': 'CPZWater SS transformation.bin', 'ARZ': 'ARZWater SS transformation.bin'}
TAILS_COLOURS = (11, 15, 14)   # PalCycle_SuperTails' order


def words(data):
    return [int.from_bytes(data[i:i + 2], 'big') for i in range(0, len(data), 2)]


def pack(ws):
    return b''.join(w.to_bytes(2, 'big') for w in ws)


def rgb(c):
    return ((c >> 1) & 7, (c >> 5) & 7, (c >> 9) & 7)


def colour(r, g, b):
    return r << 1 | g << 5 | b << 9


def references(zone):
    pairs = []
    dry = words((PAL / 'SonicAndTails.bin').read_bytes())[2:16]
    wet = words((PAL / f'{zone} underwater.bin').read_bytes())[2:16]
    pairs += zip(dry, wet)
    dry = words((PAL / 'Knuckles and Tails.bin').read_bytes())[2:6]
    wet = words((PAL / f'{zone} underwater Knuckles.bin').read_bytes())[2:6]
    pairs += zip(dry, wet)
    if zone in SUPER_SONIC:
        pairs += zip(words((PAL / 'Super Sonic transformation.bin').read_bytes()),
                     words((PAL / SUPER_SONIC[zone]).read_bytes()))
    return [(rgb(d), rgb(w)) for d, w in pairs]


def tint(c, refs):
    """Move c like the nearest dry reference colour(s) moved under water."""
    if c == 0:
        return 0
    r = rgb(c)
    dist = lambda d: sum((a - b) ** 2 for a, b in zip(d, r))
    best = min(dist(d) for d, _ in refs)
    near = [(d, w) for d, w in refs if dist(d) == best]
    shift = [sum(w[k] - d[k] for d, w in near) / len(near) for k in range(3)]
    return colour(*(min(7, max(0, round(v + s))) for v, s in zip(r, shift)))


def super_tails_dry():
    """PalCycle_SuperTails_Colours from code/SuperTails.asm (rept blocks expanded)."""
    text = (ROOT / 'code' / 'SuperTails.asm').read_text()
    body = text.split('PalCycle_SuperTails_Colours:', 1)[1]
    frames = []
    lines = iter(body.splitlines())
    for line in lines:
        line = line.split(';')[0].strip()
        if not line:
            continue
        m = re.match(r'rept\s+(\d+)$', line)
        if m:
            inner = next(lines).split(';')[0].strip()
            assert next(lines).strip() == 'endm'
            frames += [inner] * int(m[1])
        elif line.startswith('dc.w'):
            frames.append(line)
        else:
            break
    return [[int(v.strip().lstrip('$'), 16) for v in f[4:].split(',')] for f in frames]


def generate():
    outputs = {}
    knuckles = words((PAL / 'Super Knuckles cycle.bin').read_bytes())
    tails = super_tails_dry()
    for zone in ZONES:
        refs = references(zone)
        outputs[PAL / f'Super Knuckles cycle {zone} underwater.bin'] = pack(tint(c, refs) for c in knuckles)
        # his own colours (the fade's first frames) use the zone's real
        # underwater ones, so turning back ends exactly on them
        wet = words((PAL / f'{zone} underwater.bin').read_bytes())
        dry = words((PAL / 'SonicAndTails.bin').read_bytes())
        out = []
        for frame in tails:
            for c, index in zip(frame[:3], TAILS_COLOURS):
                out.append(wet[index] if c == dry[index] else tint(c, refs))
            out.append(0)
        outputs[PAL / f'Super Tails {zone} underwater.bin'] = pack(out)
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
