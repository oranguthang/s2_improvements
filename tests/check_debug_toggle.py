"""Check P1's debug cursor in a real Genesis Plus GX core, in 1P and VS.

Uses the same --harness directory as check_demo_cycle.py. No debug input is
injected into RAM: B, cursor movement and player 2's B use controller input.
Only the character/menu choices and the enabled debug cheat are set in RAM.
"""
import argparse
import json
from pathlib import Path
import re
import sys

DEFAULT_HARNESS = r'C:\Users\Daniel\Documents\Codex\2026-10-03\d-projects-oranguthang-s2-improvements\work'


def symbols(path):
    table = path.read_text(errors='replace').split('Symbol Table (* = unused):', 1)[1]
    return {m[1]: int(m[2], 16) & 0xFFFFFFFF for m in
            re.finditer(r'([A-Za-z_][\w.]*)\s*:\s*([0-9A-F]+)\s+[C-](?=\s*\|)', table)}


def check(Retro, rom, s, option, player2=None, special=False):
    r = Retro(str(rom))
    try:
        r.run(850)
        for _ in range(4):
            r.ww(s['Player_option'], option)
            if player2 is not None:
                r.wb(s['VS_player2'], player2)
            r.wb(s['Title_screen_option'], int(player2 is not None))
            r.run(1, [3])  # Start, including skipping the title intro
            r.run(120)
            if r.rb(s['Game_Mode']) != s['GameModeID_TitleScreen']:
                break
        if player2 is not None:
            assert r.rb(s['Game_Mode']) == s['GameModeID_2PLevelSelect']
            if special:
                r.wb(s['Current_Zone_2P'], 4)
            r.run(1, [3])
        r.run(450)
        mode = s['GameModeID_SpecialStage'] if special else s['GameModeID_Level']
        assert r.rb(s['Game_Mode']) == mode, (option, player2, r.rb(s['Game_Mode']))
        r.ww(s['Debug_mode_flag'], 1)
        debug = s['Debug_placement_mode']
        main = s['MainCharacter']
        sidekick = s['Sidekick']

        def graphics(obj):
            mapping = (r.rw(obj + s['mappings']) << 16) | r.rw(obj + s['mappings'] + 2)
            return r.rb(obj), mapping, r.rw(obj + s['art_tile'])

        if special:
            for _ in range(3):
                r.run(1, [0])
                r.run(5)
                assert r.rw(debug) == 0, 'Special Stage entered placement'
            return {'option': option, 'player2': player2, 'special_stage_unchanged': True}

        original = graphics(main)
        original_p2 = graphics(sidekick)
        for _ in range(3):
            r.run(1, [0])  # Genesis B
            r.run(5)
            assert r.rw(debug) == 0x201, ('did not enter cursor', option, player2)
            assert r.rb(main + s['mappings']) == s['ObjID_Ring'], 'cursor is not a ring'
            x = r.rw(main + s['x_pos'])
            r.run(6, [7])  # Right
            assert r.rw(main + s['x_pos']) > x, 'cursor cannot move'
            if player2 is not None:
                r.run(1, (), [0])
                r.run(3)
                assert r.rw(debug) == 0x201, 'player 2 exited player 1 cursor'
            r.run(1, [0])
            r.run(5)
            assert r.rw(debug) == 0, ('cursor re-entered on exit', option, player2)
            assert graphics(main) == original, ('player 1 graphics not restored', option, player2)
            if player2 is not None:
                assert graphics(sidekick) == original_p2, 'player 2 graphics changed'
                r.run(1, (), [0])
                r.run(3)
                assert r.rw(debug) == 0, 'player 2 enabled player 1 cursor'
                assert r.rb(s['P2_context_active']) == 0
            if option == s['PlayerOption_TailsAlone']:
                tails = s['VS_Tails_Tails_P1'] if player2 is not None else s['Tails_Tails']
                assert r.rb(tails) == s['ObjID_TailsTails'], 'tails object lost'
                assert r.rw(tails + s['parent']) == main & 0xFFFF
        return {'option': option, 'player2': player2, 'round_trips': 3,
                'cursor_moves': True, 'graphics_restored': True}
    finally:
        r.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('rom', nargs='?', type=Path, default=Path('s2built.bin'))
    parser.add_argument('lst', nargs='?', type=Path, default=Path('s2.lst'))
    parser.add_argument('--harness', default=DEFAULT_HARNESS)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    sys.path.insert(0, args.harness)
    from retro import Retro
    s = symbols(args.lst)
    rom = args.rom.resolve()
    results = [check(Retro, rom, s, option) for option in range(s['PlayerOption_Count'])]
    for option in (s['PlayerOption_SonicAlone'], s['PlayerOption_TailsAlone'], s['PlayerOption_KnucklesAlone']):
        for player2 in range(s['VSPlayer2_Count']):
            results.append(check(Retro, rom, s, option, player2))
        results.append(check(Retro, rom, s, option, s['VSPlayer2_Tails'], special=True))
    output = json.dumps(results, indent=2) + '\n'
    if args.report:
        args.report.write_text(output)
    print(output, end='')


if __name__ == '__main__':
    main()
