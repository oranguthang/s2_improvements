"""Check that VS results fade out without dropping split-screen interrupts."""
import json
from pathlib import Path

from unicorn import UC_HOOK_CODE

from test_stage1 import CPU


def selected_fade(repo, two_player, results_screen):
    cpu = CPU(repo)
    calls = []

    def record(name):
        def hook(uc, address, size, user_data):
            calls.append(name)
        return hook

    for name in ('VS_FadeOut', 'Pal_FadeToBlack'):
        cpu.uc.hook_add(UC_HOOK_CODE, record(name), begin=cpu.s[name], end=cpu.s[name])
        cpu.skip(name)
    cpu.write('Two_player_mode', two_player, 2)
    cpu.write('Results_Screen_2P', results_screen, 2)
    cpu.call('TwoPlayerResults_FadeOut')
    return calls


def main():
    repo = Path(__file__).resolve().parents[1]
    cases = 0
    for results_screen in range(5):
        calls = selected_fade(repo, 0, results_screen)
        assert calls == ['Pal_FadeToBlack'], ('inactive VS', results_screen, calls)
        cases += 1

        expected = 'VS_FadeOut' if results_screen <= 2 else 'Pal_FadeToBlack'
        calls = selected_fade(repo, 1, results_screen)
        assert calls == [expected], ('active VS', results_screen, calls)
        cases += 1

    cpu = CPU(repo)
    waits = []
    colour_updates = []

    def on_wait(uc, address, size, user_data):
        waits.append(cpu.read('Vint_routine'))

    def on_colours(uc, address, size, user_data):
        colour_updates.append(address)

    cpu.uc.hook_add(UC_HOOK_CODE, on_wait, begin=cpu.s['WaitForVint'], end=cpu.s['WaitForVint'])
    cpu.uc.hook_add(
        UC_HOOK_CODE, on_colours,
        begin=cpu.s['Pal_FadeToBlack.UpdateAllColours'],
        end=cpu.s['Pal_FadeToBlack.UpdateAllColours'],
    )
    cpu.skip('WaitForVint')
    cpu.skip('Pal_FadeToBlack.UpdateAllColours')
    cpu.call('VS_FadeOut')
    assert len(waits) == 16, len(waits)
    assert waits == [cpu.s['VintID_Pause']] * 16, waits
    assert len(colour_updates) == 8, len(colour_updates)

    print(json.dumps({
        'fade_selection_cases': cases,
        'split_screen_vint_frames': len(waits),
        'colour_updates': len(colour_updates),
        'passed': True,
    }, indent=2))


if __name__ == '__main__':
    main()
