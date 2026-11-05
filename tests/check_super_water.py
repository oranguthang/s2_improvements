"""Check actual ROM water art, zone-specific Super cycles and normal reversion.
Build first. Requires Unicorn, like the other CPU regression checks.
"""
import sys
from pathlib import Path
from check_super_music import c2

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from nemesis import decode
from neutral_water import generate
from super_water import generate as generate_cycles, words

TAILS = [(0x46A,0x08E,0x0AE), (0x46A,0x2AE,0x4CE),
         (0x46C,0x4CE,0x8CE), (0x48E,0x8CE,0xAEE),
         (0x46C,0x4CE,0x8CE), (0x46A,0x2AE,0x4CE)]

def main():
    c = c2()
    packed = generate()
    ptr = c.s['ArtNem_WaterSurface2']
    assert c.rom[ptr:ptr+len(packed)] == packed, 'ROM still uses old blue water art'
    water = decode(packed)
    assert not any(i in (2,3,4,5) for b in water for i in (b >> 4, b & 15))
    dry = (ROOT / 'art/palettes/SonicAndTails.bin').read_bytes()
    grey = [int.from_bytes(dry[2*i:2*i+2], 'big') for i in (6,7,8,9)]
    assert all((v & 14) == (v >> 4 & 14) == (v >> 8 & 14) for v in grey)
    frames = 0
    generated = generate_cycles()
    for path, expected in generated.items():
        assert path.read_bytes() == expected, path
    for zone, name in [('chemical_plant_zone','CPZ'),('aquatic_ruin_zone','ARZ'),('hidden_palace_zone','HPZ')]:
        wet = (ROOT / f'art/palettes/{name} underwater.bin').read_bytes()
        tails_wet = words(generated[ROOT / f'art/palettes/Super Tails {name} underwater.bin'])
        wet_cycle = [tuple(tails_wet[i:i+3]) for i in range(24, 48, 4)]
        assert (wet_cycle != TAILS) == (name == 'CPZ')
        for index, expected in enumerate(TAILS):
            c = c2(); c.w('Game_Mode',12); c.w('Water_flag',1); c.w('Current_Zone',c.s[zone])
            c.uc.mem_write(c.s['Normal_palette'],dry); c.uc.mem_write(c.s['Underwater_palette'],wet)
            c.w('Super_Sonic_palette',0xff); c.w('Palette_timer',0); c.w('Palette_frame',0x30+8*index,2)
            before = {p:bytes(c.uc.mem_read(c.s[p]+12,8)) for p in ('Normal_palette','Underwater_palette')}
            c.call('PalCycle_SuperTails')
            for pal in before:
                expected_cycle = expected if pal == 'Normal_palette' else wet_cycle[index]
                assert tuple(c.r(c.s[pal]+2*i,2) for i in (4,3,2)) == expected_cycle, (name,index,pal)
                assert bytes(c.uc.mem_read(c.s[pal]+12,8)) == before[pal], 'water grey ramp changed'
            frames += 1
        # The pose/fade back uses real normal underwater fur, not a guessed RGB tint.
        for index in range(6):
            c = c2(); c.w('Water_flag',1); c.w('Current_Zone',c.s[zone])
            c.w('Super_Sonic_palette',1); c.w('Palette_timer',0); c.w('Palette_frame',8*index,2)
            c.call('PalCycle_SuperTails')
            assert tuple(c.r(c.s['Underwater_palette']+2*i,2) for i in (4,3,2)) == tuple(int.from_bytes(wet[2*i:2*i+2],'big') for i in (11,15,14))
        source = (ROOT / 'art/palettes/Super Knuckles cycle.bin').read_bytes()
        wet_source = generated[ROOT / f'art/palettes/Super Knuckles cycle {name} underwater.bin']
        assert (source != wet_source) == (name in ('CPZ', 'ARZ'))
        for index in range(len(source)//6):
            c = c2(); c.w('Water_flag',1); c.w('Current_Zone',c.s[zone])
            c.uc.mem_write(c.s['Normal_palette'],dry); c.uc.mem_write(c.s['Underwater_palette'],wet)
            c.w('Super_Sonic_palette',0xff); c.w('Palette_timer',0); c.w('Palette_frame',6*index,2)
            c.call('PalCycle_SuperKnuckles')
            for pal, cycle in [('Normal_palette', source), ('Underwater_palette', wet_source)]:
                expected = tuple(words(cycle[6*index:6*index+6]))
                assert tuple(c.r(c.s[pal]+2*i,2) for i in (2,3,5)) == expected, (name,index,pal)
            frames += 1
        c.w('Super_Sonic_palette',2); c.call('PalCycle_SuperKnuckles')
        normal = (ROOT / f'art/palettes/{name} underwater Knuckles.bin').read_bytes()
        assert tuple(c.r(c.s['Underwater_palette']+2*i,2) for i in (2,3,5)) == tuple(int.from_bytes(normal[2*i:2*i+2],'big') for i in (2,3,5))
    print(f'ROM uses neutral ARZ water; {frames} dry/wet Super cycle frames and normal underwater pose/reversion passed')

if __name__ == '__main__':
    main()
