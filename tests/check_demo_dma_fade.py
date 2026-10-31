"""Check that leaving a demo drains player-art DMA requests before fading."""
import argparse
import ctypes as C
import json
from pathlib import Path
import sys

from check_demo_start import symbols, snapshot, restore


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
    pending = []
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
        assert r.rb(s['Game_Mode']) == s['GameModeID_Demo']
        baseline = snapshot(r)
        for demo_frame in range(args.cases):
            restore(r, baseline)
            r.run(demo_frame)
            r.run(1, [3])
            for _ in range(10):
                if r.rb(s['Game_Mode']) == s['GameModeID_TitleScreen']:
                    break
                r.run(1)
            assert r.rb(s['Game_Mode']) == s['GameModeID_TitleScreen'], demo_frame
            r.run(1)  # let the first fade V-int process the previous level's queue
            queue_used = ((r.rw(s['VDP_Command_Buffer_Slot'])
                           - (s['VDP_Command_Buffer'] & 0xFFFF)) // 14)
            if queue_used:
                pending.append({
                    'demo_frame': demo_frame,
                    'queue_used': queue_used,
                    'sonic_frame': r.rb(s['MainCharacter'] + s['mapping_frame']),
                    'tails_frame': r.rb(s['Sidekick'] + s['mapping_frame']),
                })
                if args.output:
                    args.output.mkdir(parents=True, exist_ok=True)
                    if len(pending) <= 5:
                        r.shot(str(args.output / f'demo-dma-pending-{demo_frame}.png'))
        print(json.dumps({
            'demo_start_cases': args.cases,
            'pending_dma_cases': pending,
        }, indent=2))
    finally:
        r.close()


if __name__ == '__main__':
    main()
