"""Generate Super Tails/Knuckles underwater tables for CPZ, ARZ and HPZ.

Use hand-tuned water ramps in Chemical Plant, and for Knuckles in
Aquatic Ruin. The other cycles keep S3K's shared dry and wet colours.
Tails keeps each zone's real normal fur colours during the transformation
pose/reversion. Knuckles' reversion already restores its real water palette
in code/Knuckles.asm. Source order stays 11/15/14 for Tails and 2/3/5 for
Knuckles; Super Tails gameplay writes those values to 4/3/2.

Usage: python tools/super_water.py [--check]
"""
import argparse, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAL = ROOT / 'art' / 'palettes'
ZONES = ('CPZ', 'ARZ', 'HPZ')
TAILS_COLOURS = (11, 15, 14)   # PalCycle_SuperTails' order

# Chemical Plant tints the bright colours magenta. Preserve a distinct
# shadow, body and highlight throughout the pulse.
CPZ_TAILS_PULSE = (
    (0xA4A, 0xC6E, 0xE8E),
    (0xA6C, 0xC8E, 0xEAE),
    (0xC8C, 0xEAE, 0xECE),
)

# Five steps towards the peak, followed by the dim hold frame. Chemical
# Plant has purple shadows; Aquatic Ruin uses a cooler blue-lilac ramp.
KNUCKLES_WATER_RAMPS = {
    'CPZ': (
        (0xC26, 0xE2C, 0xE4E),
        (0xC48, 0xE4C, 0xE6E),
        (0xC6A, 0xE6E, 0xE8E),
        (0xC6C, 0xE8E, 0xEAE),
        (0xE8C, 0xEAE, 0xECE),
        (0xA04, 0xE0A, 0xE2A),
    ),
    'ARZ': (
        (0xA26, 0xC4A, 0xE6C),
        (0xA48, 0xC6C, 0xE8C),
        (0xC68, 0xE8C, 0xEAC),
        (0xC8A, 0xEAC, 0xECC),
        (0xEAA, 0xECC, 0xEEE),
        (0x804, 0xA0A, 0xA2C),
    ),
}


def words(data):
    return [int.from_bytes(data[i:i + 2], 'big') for i in range(0, len(data), 2)]


def pack(ws):
    return b''.join(w.to_bytes(2, 'big') for w in ws)


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
    knuckles = (PAL / 'Super Knuckles cycle.bin').read_bytes()
    tails = super_tails_dry()
    assert len(tails) == 12
    for zone in ZONES:
        knuckles_cycle = knuckles
        if zone in KNUCKLES_WATER_RAMPS:
            ramp = KNUCKLES_WATER_RAMPS[zone]
            frames = ramp[:5] + ramp[3::-1] + ramp[5:]
            knuckles_cycle = pack(colour for frame in frames for colour in frame)
            assert len(knuckles_cycle) == len(knuckles)
        outputs[PAL / f'Super Knuckles cycle {zone} underwater.bin'] = knuckles_cycle

        wet = words((PAL / f'{zone} underwater.bin').read_bytes())
        normal_fur = tuple(wet[i] for i in TAILS_COLOURS)
        cycle = [tuple(frame[:3]) for frame in tails[6:]]
        if zone == 'CPZ':
            low, middle, peak = CPZ_TAILS_PULSE
            cycle = [normal_fur, low, middle, peak, middle, low]
        frames = [normal_fur] * 6 + cycle
        outputs[PAL / f'Super Tails {zone} underwater.bin'] = pack(
            colour for frame in frames for colour in (*frame, 0)
        )
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
    for p in stale:
        p.write_bytes(outputs[p])
        print('wrote', p.relative_to(ROOT))


if __name__ == '__main__':
    main()
