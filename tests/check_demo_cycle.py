"""Play the title demo cycle in Genesis Plus GX and summarise each demo.

Usage: python tests/check_demo_cycle.py [ROM] [LST] [--harness DIR] [--demos N]

The harness directory must contain retro.py and
stage2-assets/genesis/genesis_plus_gx_libretro.dll (the Codex work folder
from the 2026-10-03 session has both). For every demo it prints the zone,
Demo_number, frames played, frames Sonic spent carried by Tails, frames
Tails was flying and frames Sonic was dead. A healthy cycle has no deaths.
"""
from pathlib import Path
import argparse, os, re, sys

DEFAULT_HARNESS = r'C:\Users\Daniel\Documents\Codex\2026-10-03\d-projects-oranguthang-s2-improvements\work'

parser = argparse.ArgumentParser()
parser.add_argument('rom', nargs='?', default='s2built.bin')
parser.add_argument('lst', nargs='?', default='s2.lst')
parser.add_argument('--harness', default=DEFAULT_HARNESS)
parser.add_argument('--demos', type=int, default=8)
args = parser.parse_args()
rom, lst = Path(args.rom).resolve(), Path(args.lst).resolve()

sys.path.insert(0, args.harness)
os.chdir(Path(args.harness).parent)  # retro.py resolves its assets relative to this
from retro import Retro

table = lst.read_text(errors='replace').split('Symbol Table (* = unused):', 1)[1]
S = {m[1]: int(m[2], 16) & 0xFFFFFFFF for m in
     re.finditer(r'([A-Za-z_][\w.]*)\s*:\s*([0-9A-F]+)\s+[C-](?=\s*\|)', table)}

r = Retro(str(rom))
GM, ZA, DN, DF = S['Game_Mode'], S['Current_ZoneAndAct'], S['Demo_number'], S['Demo_mode_flag']
MC, SK = S['MainCharacter'], S['Sidekick']
GAMEMODE_DEMO = 8
STATUS_SECONDARY, FLYING, ROUTINE, X_POS = 0x2B, 0x20, 0x24, 8
CARRY_MASK = 1 << 3

current, stats, out = None, None, []
for _ in range(60 * 60 * 8):
    r.run(1)
    if r.rw(DF) and r.rb(GM) == GAMEMODE_DEMO:
        key = (r.rw(ZA), r.rw(DN))
        if key != current:
            if stats:
                out.append(stats)
            current = key
            stats = dict(zone=hex(key[0]), demo_number=key[1], frames=0, carry=0,
                         tails_flying=0, sonic_dead=0, max_x=0)
        stats['frames'] += 1
        stats['carry'] += bool(r.rb(MC + STATUS_SECONDARY) & CARRY_MASK)
        stats['tails_flying'] += bool(r.rb(SK + FLYING))
        stats['sonic_dead'] += r.rb(MC + ROUTINE) >= 6
        stats['max_x'] = max(stats['max_x'], r.rw(MC + X_POS))
    elif stats:
        out.append(stats)
        current, stats = None, None
    if len(out) >= args.demos:
        break
if stats:
    out.append(stats)
r.close()
for s in out:
    print(s)
