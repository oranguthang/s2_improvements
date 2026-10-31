"""Press Start on different demo frames and compare the resulting title screen."""
import argparse
import ctypes as C
import hashlib
import json
from pathlib import Path
import re
import sys


def symbols(path):
    table = path.read_text(errors='replace').split('Symbol Table (* = unused):', 1)[1]
    return {m[1]: int(m[2], 16) & 0xFFFFFFFF for m in
            re.finditer(r'([A-Za-z_][\w.]*)\s*:\s*([0-9A-F]+)\s+[C-](?=\s*\|)', table)}


def snapshot(r):
    size = r.core.retro_serialize_size()
    r.core.retro_serialize.argtypes = [C.c_void_p, C.c_size_t]
    r.core.retro_serialize.restype = C.c_bool
    buffer = C.create_string_buffer(size)
    assert r.core.retro_serialize(buffer, size)
    return buffer


def restore(r, buffer):
    r.core.retro_unserialize.argtypes = [C.c_void_p, C.c_size_t]
    r.core.retro_unserialize.restype = C.c_bool
    assert r.core.retro_unserialize(buffer, len(buffer))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('rom', nargs='?', type=Path, default=Path('s2built.bin'))
    parser.add_argument('lst', nargs='?', type=Path, default=Path('s2.lst'))
    parser.add_argument('--harness', required=True)
    parser.add_argument('--cases', type=int, default=120)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    sys.path.insert(0, args.harness)
    from retro import Retro

    s = symbols(args.lst)
    r = Retro(str(args.rom.resolve()))
    mismatches = []
    try:
        r.run(850)
        assert r.rb(s['Game_Mode']) == s['GameModeID_TitleScreen']
        r.ww(s['Demo_Time_left'], 1)
        r.run(2)
        for _ in range(600):
            if (r.rb(s['Game_Mode']) == s['GameModeID_Demo']
                    and not r.rb(s['Game_Mode']) & (1 << s['GameModeFlag_TitleCard'])):
                if r.rw(s['Demo_mode_flag']) and r.rw(s['Level_started_flag']):
                    break
            r.run(1)
        assert r.rb(s['Game_Mode']) == s['GameModeID_Demo'], hex(r.rb(s['Game_Mode']))
        baseline = snapshot(r)
        reference = None
        for demo_frame in range(args.cases):
            restore(r, baseline)
            r.run(demo_frame)
            r.run(1, [3])
            for _ in range(10):
                if r.rb(s['Game_Mode']) == s['GameModeID_TitleScreen']:
                    break
                r.run(1)
            assert r.rb(s['Game_Mode']) == s['GameModeID_TitleScreen'], demo_frame
            for _ in range(700):
                if r.rb(s['IntroSonic'] + s['obj0e_intro_complete']):
                    break
                r.run(1)
            assert r.rb(s['IntroSonic'] + s['obj0e_intro_complete']), demo_frame
            r.run(2)
            frame = r.frame[0]
            digest = hashlib.sha256(frame).hexdigest()
            if reference is None:
                reference = digest
                if args.output:
                    args.output.mkdir(parents=True, exist_ok=True)
                    r.shot(str(args.output / 'demo-title-reference.png'))
            if digest != reference:
                mismatches.append({'demo_frame': demo_frame, 'sha256': digest})
                if args.output and len(mismatches) <= 5:
                    r.shot(str(args.output / f'demo-title-mismatch-{demo_frame}.png'))
        print(json.dumps({
            'demo_start_cases': args.cases,
            'mismatches': mismatches,
            'reference_sha256': reference,
        }, indent=2))
    finally:
        r.close()


if __name__ == '__main__':
    main()
