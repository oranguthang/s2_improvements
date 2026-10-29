"""Make the data Hill Top Zone needs in 2P VS mode (FeatureHTZVS).

Usage: python tools/htz_vs.py [--check]

After the Sonic Retro guide "Add Hill Top Zone to 2 Player VS Mode" (by
E-122-Psi), with its manual SonLVL steps done by this script:
- the game results screen's Special Stage rows become Hill Top rows
  (HILL TOP 1, 2 and S.S, as for the other zones);
- level/objects/HTZ_1_2P.bin and HTZ_2_2P.bin are the 1-player layouts
  without the earthquakes' rising lava (Obj30), with the long-distance flag
  on the lifts (Obj16, which also get the remember-state flag) and Rexons
  (Obj96), and with a signpost after act 2's 2P camera limit; the 2P
  objects manager loads each 256-pixel column into a block of 12 object
  slots and stops loading for good when a column does not fit, so act 2's
  two crowded columns lose a spike row and two Spikers at the top edge of
  the level, and a path swapper moves 8 pixels into the next column;
- mappings/sprite/obj93_2P.asm are the Spiker's mappings with its own tiles
  moved from $520 to $760 (ArtTile_ArtNem_Spiker_2P): in 2P VS tiles
  $500-$57F hold player 2's plane A name table.
"""
import argparse, re, struct, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import enigma

WIDTH = 40   # the results screens' plane maps are 40 cells wide


def font(text):
    """Menu font cells: A-Z from $1E, 0-9 from $10, '.' $1D, space 0."""
    cells = []
    for c in text:
        if c == ' ':
            cells.append(0)
        elif c == '.':
            cells.append(0x1D)
        elif c.isdigit():
            cells.append(0x10 + int(c))
        else:
            cells.append(0x1E + ord(c) - ord('A'))
    return cells


def game_results():
    source = (ROOT / 'mappings/misc/2P Game Results.eni').read_bytes()
    words = enigma.decode(source)
    out = [0] * len(words)

    def row(r):
        return words[r * WIDTH:(r + 1) * WIDTH]

    def put(r, cells, col=0):
        out[r * WIDTH + col:r * WIDTH + col + len(cells)] = cells

    assert row(18)[3:16] == font('SPECIAL STAGE')
    assert row(14)[4:16] == font('CASINO NIGHT')
    assert row(25)[25:28] == font('THE')
    # five zones of three rows (act 1, act 2 and the tiebreak S.S, or the
    # three Special Stages) need the whole screen: the title and WINS move up
    # a row, the blocks keep one blank row between them, TOTAL and THE GAME
    # follow (Setup2PResults_Game and Obj21_PositionTable match these rows)
    for new, old in ((1, 2), (2, 3), (3, 4),
                     (4, 6), (5, 7), (6, 8),          # EMERALD HILL
                     (8, 10), (9, 11), (10, 12),      # MYSTIC CAVE
                     (12, 14), (13, 15), (14, 16),    # CASINO NIGHT
                     (16, 18), (17, 19), (18, 16),    # HILL TOP 1, 2 and S.S
                     (20, 18), (21, 19), (22, 20),    # SPECIAL STAGE 1, 2, 3
                     (24, 22), (26, 25)):             # TOTAL, THE GAME
        put(new, row(old))
    put(16, font('     HILL TOP'), 3)
    packed = enigma.encode(out)
    assert enigma.decode(packed) == out
    return {ROOT / 'mappings/misc/2P Game Results HTZ.eni': packed}


REMEMBER = 0x8000      # object layout flags (the y word's top bits)
LONG_DISTANCE = 0x1000
OBJ_SIGNPOST, OBJ_LIFT, OBJ_RISING_LAVA, OBJ_REXON = 0x0D, 0x16, 0x30, 0x96
BLOCK_SLOTS = 12
# act 2 objects dropped or moved to keep every column within a block
ACT2_REMOVE = [(0x0E68, 0x374, 0x36, 0x00),   # spikes in the corridor next to a breakable shaft
               (0x1910, 0x078, 0x92, 0x0A),   # Spikers at the top edge of the level
               (0x1950, 0x088, 0x92, 0x0A)]
ACT2_MOVE = {(0x0EF8, 0x480, 0x03, 0x19): 0x0F00}   # path swapper
ACT2_SIGNPOST = (0x2E20, 0x530)   # 2P camera limit $2D80 (LevEvents_HTZ2) + $A0, 8px above the floor like act 1's


def read_layout(path):
    data = path.read_bytes()
    objects = []
    for i in range(0, len(data), 6):
        x, y, obj, subtype = struct.unpack('>HHBB', data[i:i + 6])
        if x == 0xFFFF:
            break
        objects.append([x, y, obj, subtype])
    return objects


def write_layout(objects):
    objects = sorted(objects, key=lambda o: o[0])   # the objects manager reads them in x order
    return b''.join(struct.pack('>HHBB', *o) for o in objects)


def object_layouts():
    outputs = {}
    for act in (1, 2):
        objects = read_layout(ROOT / f'level/objects/HTZ_{act}.bin')
        assert sum(o[2] == OBJ_RISING_LAVA for o in objects) == (3, 4)[act - 1]
        objects = [o for o in objects if o[2] != OBJ_RISING_LAVA]
        for o in objects:
            if o[2] == OBJ_LIFT:
                o[1] |= REMEMBER | LONG_DISTANCE
            elif o[2] == OBJ_REXON:
                o[1] |= LONG_DISTANCE
        if act == 2:
            for key in ACT2_REMOVE:
                match = [o for o in objects if (o[0], o[1] & 0xFFF, o[2], o[3]) == key]
                assert len(match) == 1, key
                objects.remove(match[0])
            for key, x in ACT2_MOVE.items():
                match = [o for o in objects if (o[0], o[1] & 0xFFF, o[2], o[3]) == key]
                assert len(match) == 1, key
                match[0][0] = x
            assert not any(o[2] == OBJ_SIGNPOST for o in objects)
            objects.append([ACT2_SIGNPOST[0], ACT2_SIGNPOST[1], OBJ_SIGNPOST, 0])
        columns = {}
        for o in objects:
            if not o[1] & LONG_DISTANCE:   # long-distance objects use the shared slots
                columns[o[0] >> 8] = columns.get(o[0] >> 8, 0) + 1
        full = {f'${c:X}00': n for c, n in columns.items() if n > BLOCK_SLOTS}
        assert not full, f'act {act} columns over {BLOCK_SLOTS} objects: {full}'
        outputs[ROOT / f'level/objects/HTZ_{act}_2P.bin'] = write_layout(objects)
    return outputs


SPIKER_TILES = range(0x520, 0x534)   # ArtTile_ArtNem_Spiker, 20 tiles
SPIKER_2P = 0x760                    # ArtTile_ArtNem_Spiker_2P


def spiker_mappings():
    text = (ROOT / 'mappings/sprite/obj93.asm').read_text()
    moved = 0

    def piece(m):
        nonlocal moved
        fields = m[2].split(', ')
        tile = int(fields[4].lstrip('$'), 16)
        if tile in SPIKER_TILES:
            fields[4] = f'${tile - SPIKER_TILES.start + SPIKER_2P:X}'
            moved += 1
        return m[1] + ', '.join(fields)

    text = re.sub(r'^(\tspritePiece\t)(.*)$', piece, text, flags=re.M)
    text = text.replace('Map_obj93', 'Map_obj93_2P')
    assert moved == 7
    header = '; Spiker for 2P VS mode (FeatureHTZVS), generated by tools/htz_vs.py from obj93.asm\n'
    return {ROOT / 'mappings/sprite/obj93_2P.asm': (header + text).encode()}


def generate():
    outputs = {}
    outputs.update(game_results())
    outputs.update(object_layouts())
    outputs.update(spiker_mappings())
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
