"""Import Knuckles' resources from the Knuckles in Sonic 2 disassembly.

Usage: python tools/import_kis2.py [--check]

Reads the files of s2disasm's knuckles-in-sonic-2 branch (commit KIS2_COMMIT,
fetched as the `upstream` remote) with `git show`, so the result does not
depend on the branch moving later. The art is already converted to Sonic 2's
palette indices there ("Pre-convert Knuckles' art"). Knuckles uses colours
2-5 of the first palette line, where Sonic's blue is, so the Knuckles
palettes are Sonic 2's with those four colours taken from KiS2; Tails' colours
stay, which is what Knuckles and Tails games need.

Writes the files listed in COPIES, the palettes and the KNUCKLES_LAYOUTS
(level/objects/Knuckles/).
"""
import argparse, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIS2_COMMIT = 'c336fede00092017f48c9d7851e0d3728c4fae2b'
HEADER = (f'; Imported from Knuckles in Sonic 2 (s2disasm knuckles-in-sonic-2, {KIS2_COMMIT[:7]})\n'
          '; by tools/import_kis2.py\n')

# (KiS2 path, our path[, (label, new label)]); .asm files get HEADER in front
COPIES = [
    ("art/uncompressed/Knuckles' art.bin", "art/uncompressed/Knuckles' art.bin"),
    ('mappings/sprite/Knuckles.asm', 'mappings/sprite/Knuckles.asm'),
    ('mappings/spriteDPLC/Knuckles.asm', 'mappings/spriteDPLC/Knuckles.asm'),
    ('art/nemesis/Knuckles lives counter.nem', 'art/nemesis/Knuckles lives counter.nem'),
    ('art/nemesis/Knuckles continue.nem', 'art/nemesis/Knuckles continue.nem'),
    ('art/nemesis/Final image of Knuckles.nem', 'art/nemesis/Final image of Knuckles.nem'),
    ('mappings/sprite/objCF.asm', 'mappings/sprite/objCF Knuckles.asm', ('Map_objCF', 'Map_objCFK')),
    ('art/palettes/Ending Sonic.bin', 'art/palettes/Ending Knuckles.bin'),
    ('art/palettes/Super Knuckles transformation.bin', 'art/palettes/Super Knuckles cycle.bin'),
    ('art/palettes/Super Knuckles revert.bin', 'art/palettes/Super Knuckles revert.bin'),
    ('art/nemesis/Signpost (Knuckles patch).nem', 'art/nemesis/Signpost Knuckles patch.nem'),
    ('art/nemesis/Monitor and contents (Knuckles patch).nem', 'art/nemesis/Monitor Knuckles patch.nem'),
    ('art/uncompressed/Title card font K.bin', 'art/uncompressed/Results letter K.bin'),
    ('art/uncompressed/Slot pictures (Knuckles patch).bin', 'art/uncompressed/Slot picture Knuckles.bin'),
    ('art/nemesis/Knuckles animation frames in special stage.nem', 'art/nemesis/Knuckles animation frames in special stage.nem'),
    ('mappings/sprite/obj09.asm', 'mappings/sprite/obj09 Knuckles.asm', ('Map_obj09', 'Map_obj09K')),
    ('mappings/spriteDPLC/obj09.asm', 'mappings/spriteDPLC/obj09 Knuckles.asm', ('DPLC_obj09', 'DPLC_obj09K')),
    ('art/palettes/Special Stage Main.bin', 'art/palettes/Special Stage Main Knuckles.bin'),
    ('mappings/sprite/obj6F.asm', 'mappings/sprite/obj6F Knuckles.asm', ('Map_obj6F', 'Map_obj6FK')),
]

KNUCKLES_COLOURS = range(2, 6)   # first palette line

# Object layouts KiS2 changed for Knuckles (invisible walls, path swappers,
# monitors and springs where his lower jump or his climbing needs them)
KNUCKLES_LAYOUTS = ['ARZ_1', 'ARZ_2', 'CNZ_1', 'CNZ_2', 'CPZ_1', 'CPZ_2', 'EHZ_1', 'EHZ_2', 'HTZ_1',
                    'HTZ_2', 'MCZ_1', 'MCZ_2', 'MTZ_1', 'MTZ_2', 'MTZ_3', 'OOZ_1', 'OOZ_2', 'WFZ_1']


def kis2(path):
    return subprocess.run(['git', '-C', str(ROOT), 'show', f'{KIS2_COMMIT}:{path}'],
                          capture_output=True, check=True).stdout


def words(data):
    return [int.from_bytes(data[i:i + 2], 'big') for i in range(0, len(data), 2)]


def pack(ws):
    return b''.join(w.to_bytes(2, 'big') for w in ws)


def with_knuckles(s2_file, colours):
    ws = words((ROOT / 'art' / 'palettes' / s2_file).read_bytes())
    for i, c in zip(KNUCKLES_COLOURS, colours):
        ws[i] = c
    return pack(ws)


def palettes():
    normal = [words(kis2('art/palettes/SonicAndTails.bin'))[i] for i in KNUCKLES_COLOURS]
    out = {'Knuckles and Tails.bin': with_knuckles('SonicAndTails.bin', normal)}
    for zone in ('CPZ', 'ARZ'):
        water = [words(kis2(f'art/palettes/{zone} underwater.bin'))[i] for i in KNUCKLES_COLOURS]
        out[f'{zone} underwater Knuckles.bin'] = with_knuckles(f'{zone} underwater.bin', water)
    # KiS2 has no Hidden Palace. Its underwater tint takes each of Sonic's colours
    # to a fixed other colour; apply the same per-channel change to Knuckles'.
    sonic = [words((ROOT / 'art/palettes/SonicAndTails.bin').read_bytes())[i] for i in KNUCKLES_COLOURS]
    hpz = [words((ROOT / 'art/palettes/HPZ underwater.bin').read_bytes())[i] for i in KNUCKLES_COLOURS]

    def channels(c):
        return [(c >> s) & 0xE for s in (0, 4, 8)]
    shift = [round(sum(channels(h)[k] - channels(s)[k] for s, h in zip(sonic, hpz)) / len(sonic)) for k in range(3)]

    def tint(c):
        ch = [min(14, max(0, v + d)) & 0xE for v, d in zip(channels(c), shift)]
        return ch[0] | ch[1] << 4 | ch[2] << 8
    out['HPZ underwater Knuckles.bin'] = with_knuckles('HPZ underwater.bin', [tint(c) for c in normal])
    return {ROOT / 'art' / 'palettes' / name: data for name, data in out.items()}


# KiS2 recoloured the shield and the invincibility stars grey, since Sonic's
# blue (colours 2-5) is Knuckles' red and green there. Its colour changes,
# found by comparing its art with Sonic 2's, are applied to this project's art.
SHIELD_GREY = {2: 8, 3: 8, 4: 8, 5: 7}
STARS_GREY = {3: 8, 4: 7, 5: 7}


def recolour(raw, mapping):
    return bytes((mapping.get(b >> 4, b >> 4) << 4) | mapping.get(b & 15, b & 15) for b in raw)


def greys():
    sys.path.insert(0, str(ROOT / 'tools'))
    import nemesis
    shield = (ROOT / 'art/uncompressed/Shield.bin').read_bytes()
    stars_nem = (ROOT / 'art/nemesis/Invincibility stars.nem').read_bytes()
    stars = recolour(nemesis.decode(stars_nem), STARS_GREY)
    packed = nemesis.encode_with_table(stars_nem, stars)
    assert nemesis.decode(packed) == stars
    # 2P VS: the uncompressed signpost (the same art as the Nemesis one) with
    # KiS2's patch at the same tiles as PlrList_SignpostKnuckles puts it
    signpost = bytearray(nemesis.decode((ROOT / 'art/nemesis/Signpost.nem').read_bytes()))
    assert bytes(signpost) == (ROOT / 'art/uncompressed/Signpost.bin').read_bytes()
    patch = nemesis.decode(kis2('art/nemesis/Signpost (Knuckles patch).nem'))
    signpost[34 * 32:34 * 32 + len(patch)] = patch
    return {ROOT / 'art/uncompressed/Shield Knuckles.bin': recolour(shield, SHIELD_GREY),
            ROOT / 'art/nemesis/Invincibility stars Knuckles.nem': packed,
            ROOT / 'art/uncompressed/Signpost Knuckles.bin': bytes(signpost)}


def generate():
    outputs = {}
    for src, dst, *rename in COPIES:
        data = kis2(src)
        if dst.endswith('.asm'):
            data = HEADER.encode() + data.replace(b'\r\n', b'\n')
            for old, new in rename:   # labels that would clash with Sonic 2's copy
                data = data.replace(old.encode(), new.encode())
        outputs[ROOT / dst] = data
    outputs.update(palettes())
    outputs.update(greys())
    for act in KNUCKLES_LAYOUTS:
        outputs[ROOT / 'level' / 'objects' / 'Knuckles' / f'{act}.bin'] = kis2(f'level/objects/{act}.bin')
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
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
        print('wrote', p.relative_to(ROOT))


if __name__ == '__main__':
    main()
