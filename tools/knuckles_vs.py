"""Make Knuckles' sprites for 2P VS mode.

Usage: python tools/knuckles_vs.py [--check]

Sonic 2's split screen draws sprites in interlace mode 2, where every sprite
cell is 8x16 pixels: two consecutive tiles. Knuckles' frames (from Knuckles in
Sonic 2, tools/import_kis2.py) use pieces of any height, so this tool redraws
each frame Knuckles uses into a bitmap (with the pieces' flips) and cuts it
again into 8x16 cells (on whichever grid offset needs the fewest tiles). Empty cells are dropped and
neighbouring cells on a cell row become one piece (up to four cells wide), so
the picture is the same and each frame needs as few tiles as possible. Frames
Knuckles never shows get no sprite. Every frame must fit the player's 32-tile
VRAM slot.

Writes art/uncompressed/Knuckles VS.bin, mappings/sprite/Knuckles VS.asm and
mappings/spriteDPLC/Knuckles VS.asm.

Sonic and Knuckles share colours 2-5 of the first palette line, so a game of
Sonic against Knuckles uses a copy of the art (Knuckles VS Sonic.bin) with
Knuckles' colours moved off Sonic's: his two reds to the shoe reds C and D,
his green socks to the yellow E, his light red to F, which that game's
palette (Sonic and Knuckles VS.bin) sets to it instead of Tails' orange, and
his own orange (F) to the yellow E. The copy shares the mappings and DPLCs.
So that Knuckles looks the same in every VS game, his socks are yellow in the
normal VS art too (VS_SOCKS).
"""
import argparse, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPPINGS = ROOT / 'mappings' / 'sprite' / 'Knuckles.asm'
DPLCS = ROOT / 'mappings' / 'spriteDPLC' / 'Knuckles.asm'
ART = ROOT / 'art' / 'uncompressed' / "Knuckles' art.bin"
SCRIPTS = ROOT / 'code' / 'Knuckles.asm'
SLOT_TILES = 32
PALETTES = ROOT / 'art' / 'palettes'
# Knuckles' colour indices in the copy for Sonic against Knuckles
SONIC_GAME_REMAP = {2: 0xD, 3: 0xC, 4: 0xE, 5: 0xF, 0xF: 0xE}
# ... and in the normal VS art: his green socks on the yellow E as well
VS_SOCKS = {4: 0xE}

# Frames set by code rather than by animation scripts (code/Knuckles.asm,
# code/KnucklesGlide.asm, code/LightDash.asm): walking and running in four
# angles, tumbling, climbing, ledges, gliding, falling and sliding.
CODE_FRAMES = (set(range(0x01, 0x31)) | set(range(0x31, 0x40)) | set(range(0xB7, 0xC0)) |
               set(range(0xC0, 0xCE)) | {0xD2})


def number(text):
    text = text.strip()
    neg = text.startswith('-')
    text = text.lstrip('-')
    value = int(text[1:], 16) if text.startswith('$') else int(text, 0)
    return -value if neg else value


def parse_frames(path, kind):
    text = path.read_text()
    names = re.findall(r'mappingsTableEntry\.w\s+(\w+)', text)
    bodies = {}
    header = 'spriteHeader' if kind == 'map' else 'dplcHeader'
    item = 'spritePiece' if kind == 'map' else 'dplcEntry'
    for m in re.finditer(r'^(\w+):\s*' + header + r'\n(.*?)^\1_End', text, re.S | re.M):
        bodies[m[1]] = [[number(v) for v in line.split(item, 1)[1].split(';')[0].split(',')]
                        for line in m[2].splitlines() if item in line]
    return [bodies[n] for n in names]


def used_frames():
    text = SCRIPTS.read_text()
    text = text[text.index('KnucklesAni_Walk:'):]
    used = set(CODE_FRAMES)
    for body in re.findall(r'^KnucklesAni_\w+:\s*((?:.*\n)*?)\s*even', text, re.M):
        values = [number(v) for line in body.splitlines()
                  for v in line.split(';')[0].replace('dc.b', '').split(',') if v.strip()]
        seq, i = values[1:], 0
        while i < len(seq):
            if seq[i] >= 0xF0:
                i += 2 if seq[i] in (0xFE, 0xFD) else 1
                continue
            used.add(seq[i])
            i += 1
    return used


def tile_pixels(art, index):
    data = art[index * 32:(index + 1) * 32]
    return [[(data[r * 4 + c // 2] >> (4 if c % 2 == 0 else 0)) & 15 for c in range(8)] for r in range(8)]


def render(pieces, tiles, art):
    pixels = {}
    for x, y, w, h, tile, xflip, yflip, pal, pri in pieces:
        assert (pal, pri) == (0, 0), 'unexpected palette line or priority'
        for col in range(w):
            for row in range(h):
                src = tile_pixels(art, tiles[tile + col * h + row])
                dc = w - 1 - col if xflip else col
                dr = h - 1 - row if yflip else row
                for py in range(8):
                    for px in range(8):
                        v = src[py][px]
                        if v:
                            sx = 7 - px if xflip else px
                            sy = 7 - py if yflip else py
                            pixels[(x + dc * 8 + sx, y + dr * 8 + sy)] = v
    return pixels


def cut(pixels):
    """Cut a bitmap into 8x16 cells, trying every grid offset; returns the
    pieces and tile data of the cut that needs the fewest tiles."""
    if not pixels:
        return [], []
    left0 = min(x for x, _ in pixels)
    top0 = min(y for _, y in pixels)
    best = None
    for ox in range(8):
        for oy in range(16):
            result = cut_at(pixels, left0 - ox, top0 - oy)
            if best is None or len(result[1]) < len(best[1]):
                best = result
    return best


def cut_at(pixels, left, top):
    right = max(x for x, _ in pixels)
    bottom = max(y for _, y in pixels)
    pieces, tiles = [], []
    for cy in range(top, bottom + 1, 16):
        cells = [cx for cx in range(left, right + 1, 8)
                 if any((cx + px, cy + py) in pixels for px in range(8) for py in range(16))]
        runs = []
        for cx in cells:
            if runs and runs[-1][-1] == cx - 8 and len(runs[-1]) < 4:
                runs[-1].append(cx)
            else:
                runs.append([cx])
        for run in runs:
            start = len(tiles)
            for cx in run:   # column-major: each column is a 2-tile cell
                for half in (0, 8):
                    data = bytearray()
                    for py in range(8):
                        row = [pixels.get((cx + px, cy + half + py), 0) for px in range(8)]
                        data += bytes(row[i] << 4 | row[i + 1] for i in range(0, 8, 2))
                    tiles.append(bytes(data))
            pieces.append((run[0], cy, len(run), 2, start))
    return pieces, tiles


def generate():
    art = ART.read_bytes()
    maps, dplcs = parse_frames(MAPPINGS, 'map'), parse_frames(DPLCS, 'dplc')
    used = used_frames()
    out_art, sequences = [], {}
    map_lines = ['; Knuckles\' sprites for 2P VS mode (8x16 cells), generated by tools/knuckles_vs.py',
                 'MapUnc_KnucklesVS:\tmappingsTable']
    plc_lines = ['; Knuckles\' DPLCs for 2P VS mode, generated by tools/knuckles_vs.py',
                 'MapRUnc_KnucklesVS:\tmappingsTable']
    map_bodies, plc_bodies = [], []
    for frame, (pieces, entries) in enumerate(zip(maps, dplcs)):
        tiles = [offset + i for count, offset in entries for i in range(count)]
        new_pieces, new_tiles = cut(render(pieces, tiles, art)) if frame in used else ([], [])
        assert len(new_tiles) <= SLOT_TILES, f'frame ${frame:X} needs {len(new_tiles)} tiles'
        key = b''.join(new_tiles)
        if key and key not in sequences:
            sequences[key] = len(out_art)
            out_art += new_tiles
        name = f'KnuxVS_{frame:02X}'
        map_lines.append(f'\tmappingsTableEntry.w\t{name}')
        plc_lines.append(f'\tmappingsTableEntry.w\tDPLC_{name}')
        body = [f'{name}:\tspriteHeader']
        body += [f'\tspritePiece\t{x}, {y}, {w}, {h}, ${t:X}, 0, 0, 0, 0' for x, y, w, h, t in new_pieces]
        map_bodies += body + [f'{name}_End', '']
        body = [f'DPLC_{name}:\tdplcHeader']
        if key:
            base, count = sequences[key], len(new_tiles)
            while count:
                n = min(count, 16)
                body.append(f'\tdplcEntry\t{n}, ${base:X}')
                base += n
                count -= n
        plc_bodies += body + [f'DPLC_{name}_End', '']
    assert len(out_art) <= 0x1000, 'the DPLC tile index is 12 bits'
    art = b''.join(out_art)
    def table(mapping):
        return bytes(mapping.get(b >> 4, b >> 4) << 4 | mapping.get(b & 15, b & 15) for b in range(256))
    remap = table(SONIC_GAME_REMAP)
    sonic, knuckles = (PALETTES / 'SonicAndTails.bin').read_bytes(), (PALETTES / 'Knuckles and Tails.bin').read_bytes()
    palette = sonic[:0xF * 2] + knuckles[5 * 2:6 * 2]  # F = Knuckles' light red (5)
    return {
        ROOT / 'art' / 'uncompressed' / 'Knuckles VS.bin': art.translate(table(VS_SOCKS)),
        ROOT / 'art' / 'uncompressed' / 'Knuckles VS Sonic.bin': art.translate(remap),
        PALETTES / 'Sonic and Knuckles VS.bin': palette,
        ROOT / 'mappings' / 'sprite' / 'Knuckles VS.asm': ('\n'.join(map_lines + [''] + map_bodies) + '\teven\n').encode(),
        ROOT / 'mappings' / 'spriteDPLC' / 'Knuckles VS.asm': ('\n'.join(plc_lines + [''] + plc_bodies) + '\teven\n').encode(),
    }


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
        print('wrote', p.relative_to(ROOT), len(data))


if __name__ == '__main__':
    main()
