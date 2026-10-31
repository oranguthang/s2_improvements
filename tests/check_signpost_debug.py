"""Check signpost art loading in normal and debug placement modes."""
import json
from pathlib import Path

from unicorn import UC_HOOK_CODE
from unicorn.m68k_const import UC_M68K_REG_D0

from test_stage1 import CPU


def run_case(repo, *, character, debug, camera_x, camera_min=0, two_player=0):
    cpu = CPU(repo)
    loads = []

    def on_load(uc, address, size, user_data):
        loads.append(uc.reg_read(UC_M68K_REG_D0) & 0xFFFF)

    cpu.uc.hook_add(UC_HOOK_CODE, on_load, begin=cpu.s['LoadPLC2'], end=cpu.s['LoadPLC2'])
    cpu.skip('LoadPLC2')
    cpu.write('Level_Has_Signpost', 1, 2)
    cpu.write('Debug_placement_mode', 1 if debug else 0, 2)
    cpu.write('Two_player_mode', two_player, 2)
    cpu.write('Main_character', character)
    cpu.write('Camera_Max_X_pos', 0x2000, 2)
    cpu.write('Camera_X_pos', camera_x, 2)
    cpu.write('Camera_Min_X_pos', camera_min, 2)
    cpu.write('Update_HUD_timer', 1)
    cpu.call('CheckLoadSignpostArt')
    return loads, cpu.read('Camera_Min_X_pos', 2)


def main():
    repo = Path(__file__).resolve().parents[1]
    cases = 0
    for character in (0, 1):
        expected = 'PLCID_Signpost' if character == 0 else 'PLCID_SignpostKnuckles'
        plc = CPU(repo).s[expected]

        loads, camera_min = run_case(repo, character=character, debug=True, camera_x=0x1F00)
        assert loads == [plc], (character, 'debug load', loads)
        assert camera_min == 0x1F00, (character, 'debug load sentinel', camera_min)
        cases += 1

        loads, camera_min = run_case(
            repo, character=character, debug=True, camera_x=0x1F00, camera_min=0x1F00
        )
        assert loads == [] and camera_min == 0x1F00, (character, 'duplicate debug load', loads)
        cases += 1

        loads, camera_min = run_case(repo, character=character, debug=True, camera_x=0x1EFF)
        assert loads == [] and camera_min == 0, (character, 'early debug load', loads)
        cases += 1

        loads, camera_min = run_case(repo, character=character, debug=False, camera_x=0x1F00)
        assert loads == [plc], (character, 'normal load', loads)
        assert camera_min == 0x1F00, (character, 'normal camera lock', camera_min)
        cases += 1

        loads, camera_min = run_case(
            repo, character=character, debug=False, camera_x=0x1F00, camera_min=0x1F00
        )
        assert loads == [] and camera_min == 0x1F00, (character, 'duplicate normal load', loads)
        cases += 1

        loads, camera_min = run_case(
            repo, character=character, debug=True, camera_x=0x1F00, two_player=1
        )
        assert loads == [] and camera_min == 0, (character, 'VS debug load', loads)
        cases += 1

    print(json.dumps({'signpost_debug_cases': cases, 'passed': True}, indent=2))


if __name__ == '__main__':
    main()
