"""Check that screen transitions cannot upload stale VS sprite-table pages."""
import json
from pathlib import Path

from unicorn import UC_HOOK_MEM_READ

from test_stage1 import CPU

BUFFERS = (
    'Sprite_Table',
    'Sprite_Table_Alternate',
    'Sprite_Table_P2',
    'Sprite_Table_P2_Alternate',
)
BUFFER_SIZE = 0x280


def main():
    repo = Path(__file__).resolve().parents[1]
    cases = 0
    for page in (0, 0xFF):
        for pending in (0, 1):
            cpu = CPU(repo)
            cpu.uc.mem_map(0xA00000, 0x20000)

            def acknowledge_z80_bus(uc, access, address, size, value, user_data):
                uc.mem_write(cpu.s['Z80_Bus_Request'], b'\0\0')

            cpu.uc.hook_add(
                UC_HOOK_MEM_READ, acknowledge_z80_bus,
                begin=cpu.s['Z80_Bus_Request'], end=cpu.s['Z80_Bus_Request'] + 1,
            )

            def finish_vdp_dma(uc, access, address, size, value, user_data):
                uc.mem_write(cpu.s['VDP_control_port'], b'\0\0')

            cpu.uc.hook_add(
                UC_HOOK_MEM_READ, finish_vdp_dma,
                begin=cpu.s['VDP_control_port'], end=cpu.s['VDP_control_port'] + 1,
            )
            cpu.write('Two_player_mode', 1, 2)
            for index, name in enumerate(BUFFERS):
                pattern = bytes((index + 1, 0xA5, page, pending)) * (BUFFER_SIZE // 4)
                cpu.uc.mem_write(cpu.s[name], pattern)
            cpu.write('Current_sprite_table_page', page)
            cpu.write('Sprite_table_page_flip_pending', pending)

            try:
                cpu.call('ClearScreen')
            except AssertionError:
                from unicorn.m68k_const import UC_M68K_REG_PC
                pc = cpu.uc.reg_read(UC_M68K_REG_PC)
                raise AssertionError(f'ClearScreen stopped at {pc:08X}') from None

            for name in BUFFERS:
                data = bytes(cpu.uc.mem_read(cpu.s[name], BUFFER_SIZE))
                assert data == bytes(BUFFER_SIZE), (page, pending, name)
            assert cpu.read('Current_sprite_table_page') == 0
            assert cpu.read('Sprite_table_page_flip_pending') == 0
            cases += 1

    print(json.dumps({
        'page_states_checked': cases,
        'sprite_buffers_cleared': len(BUFFERS),
        'bytes_per_buffer': BUFFER_SIZE,
        'passed': True,
    }, indent=2))


if __name__ == '__main__':
    main()
