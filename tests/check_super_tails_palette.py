"""Super Tails must leave shared enemy browns/oranges (11/14/15) unchanged.
Build first; requires unicorn==2.1.4. Checks actual assembled palette loaders,
all normal/fade/revert frames, dry/wet palettes and every emitted DMA task.
"""
from pathlib import Path
from check_super_music import c2
from nemesis import decode
from unicorn.m68k_const import UC_M68K_REG_D0,UC_M68K_REG_D1,UC_M68K_REG_D2,UC_M68K_REG_D3,UC_M68K_REG_D6,UC_M68K_REG_A1,UC_M68K_REG_A2

ROOT=Path(__file__).resolve().parents[1]

def tiles(c,table,art,frame,check_banks=False):
    pointer=c.s[table];cue=pointer+c.r(pointer+frame*2,2);data=b''
    for i in range(c.r(cue,2)):
        word=c.r(cue+2+i*2,2);count=(word>>12)+1;source=c.s[art]+(word&0xfff)*32
        if check_banks:assert (source&0x1ffff)+count*32<=0x20000,(frame,hex(source),count)
        data+=bytes(c.uc.mem_read(source,count*32))
    return data

def main():
    c=c2()
    lookup=tuple({14:2,15:3,11:4}.get(i,i) for i in range(16))
    for frame in range(0xa1):
        old=tiles(c,'MapRUnc_Tails','ArtUnc_Tails',frame)
        assert not any(n in [2,3,4] for b in old for n in [b>>4,b&15]),('original art already needs replacement colours',frame)
        protected=tiles(c,'MapRUnc_SoloTails','ArtUnc_SoloTails',frame,True)
        assert protected==bytes((lookup[b>>4]<<4)|lookup[b&15] for b in old),frame
    # Normal palette loads remain original; a transformation copies only its
    # own fur ramp into the blue slots before the remapped art appears.
    for loader,buffer in [('PalLoad_Now','Normal_palette'),('PalLoad_ForFade','Target_palette'),('PalLoad_Water_Now','Underwater_palette'),('PalLoad_Water_ForFade','Underwater_target_palette')]:
        for source,file in [('BGND','SonicAndTails.bin'),('CPZ_U','CPZ underwater.bin'),('ARZ_U','ARZ underwater.bin'),('HPZ_U','HPZ underwater.bin')]:
            c=c2();c.w('Player_mode',2,2);c.w('Game_Mode',12)
            c.reg(UC_M68K_REG_D0,c.s['PalID_'+source]);c.call(loader)
            data=(ROOT/'art/palettes'/file).read_bytes()
            assert bytes(c.uc.mem_read(c.s[buffer],len(data)))==data
    for mode,vs,game,state in [(0,0,12,0xff),(1,0,12,0xff),(2,1,12,0xff),(2,0,4,0xff),(2,0,16,0xff),(2,0,32,0xff),(2,0,12,0)]:
        c=c2();c.w('Player_mode',mode,2);c.w('Two_player_mode',vs,2);c.w('Game_Mode',game);c.w('Super_Sonic_palette',state)
        c.reg(UC_M68K_REG_D6,c.s['ArtUnc_Tails']);c.reg(UC_M68K_REG_A2,c.s['MapRUnc_Tails'])
        c.call('SoloTails_SelectArt');assert c.uc.reg_read(UC_M68K_REG_D6)==c.s['ArtUnc_Tails']
    c=c2();c.w('Player_mode',2,2);c.w('Game_Mode',12);c.w('Super_Sonic_palette',1)
    dry=(ROOT/'art/palettes/SonicAndTails.bin').read_bytes();c.uc.mem_write(c.s['Normal_palette'],dry)
    portrait = c.s['ArtUnc_SoloTailsLifePortraits']
    portrait_bytes = 4 * 32
    for name in ('Tails', 'Miles'):
        normal = decode((ROOT / f'art/nemesis/{name} life counter.nem').read_bytes())[:portrait_bytes]
        assert bytes(c.uc.mem_read(portrait, portrait_bytes)) == normal
        assert bytes(c.uc.mem_read(portrait + portrait_bytes, portrait_bytes)) == bytes(
            (lookup[b >> 4] << 4) | lookup[b & 15] for b in normal
        )
    assert (portrait & 0x1ffff) + 2 * portrait_bytes <= 0x20000
    portrait_vram = c.s['ArtTile_ArtNem_life_counter'] * 32
    uploads = []
    def record_portrait(cpu):
        source = cpu.uc.reg_read(UC_M68K_REG_D1)
        dest = cpu.uc.reg_read(UC_M68K_REG_D2) & 0xffff
        size = cpu.uc.reg_read(UC_M68K_REG_D3) & 0xffff
        if dest == portrait_vram:
            uploads.append((source, size))
    c.skip('QueueDMATransfer', record_portrait)
    c.call('SoloTails_BeginPalette')
    assert uploads == [(portrait + portrait_bytes, portrait_bytes // 2)]
    assert c.r('Normal_palette')==int.from_bytes(dry[:1],'big')
    assert c.r(c.s['Normal_palette']+4,2)==int.from_bytes(dry[28:30],'big')
    c.reg(UC_M68K_REG_D6,c.s['ArtUnc_Tails']);c.call('SoloTails_SelectArt')
    assert c.uc.reg_read(UC_M68K_REG_D6)==c.s['ArtUnc_SoloTails']
    c.uc.mem_write(c.s['Target_palette'],dry)
    c.w('Super_Sonic_palette',0);c.call('SoloTails_EndPalette')
    assert uploads[-1] == (portrait, portrait_bytes // 2)
    assert bytes(c.uc.mem_read(c.s['Normal_palette'],len(dry)))==dry
    # The three pilot layers reproduce the original colours exactly.
    palette=[int.from_bytes(dry[i:i+2],'big') for i in range(0,32,2)]
    for frame in range(4):
        old=tiles(c,'MapRUnc_Sonic','ArtUnc_Sonic',0x2d+frame)[:192]
        data=tiles(c,'MapRUnc_SoloSonicPilot','ArtUnc_SoloSonicPilot',frame,True)
        for i in range(384):
            shift=4 if i%2==0 else 0
            original=old[i//2]>>shift&15
            base=data[i//2]>>shift&15;middle=data[192+i//2]>>shift&15;bright=data[384+i//2]>>shift&15
            colour=palette[4] if bright else palette[2 if middle==14 else 3] if middle else palette[base]
            assert colour==palette[original],(frame,i)
    # The entire 64-entry dry/water palettes must stay stable except 2/3/4.
    cycle_states=0
    for zone,wet in [('chemical_plant_zone','CPZ'),('aquatic_ruin_zone','ARZ'),('hidden_palace_zone','HPZ')]:
        for state,frames in [(1,range(0,0x30,8)),(0xff,range(0x30,0x60,8)),(2,range(0x28,-1,-8))]:
            for frame in frames:
                c=c2();c.w('Game_Mode',12);c.w('Water_flag',1);c.w('Current_Zone',c.s[zone])
                for buffer,file in [('Normal_palette','SonicAndTails.bin'),('Underwater_palette',wet+' underwater.bin')]:
                    data=(ROOT/'art/palettes'/file).read_bytes();c.uc.mem_write(c.s[buffer],data)
                before={b:bytes(c.uc.mem_read(c.s[b],128)) for b in ['Normal_palette','Underwater_palette']}
                c.w('Super_Sonic_palette',state);c.w('Palette_timer',0);c.w('Palette_frame',frame,2)
                c.call('PalCycle_SuperTails')
                for buffer,data in before.items():
                    after=bytes(c.uc.mem_read(c.s[buffer],128))
                    for i in range(64):
                        if i not in [2,3,4]:assert after[i*2:i*2+2]==data[i*2:i*2+2],(buffer,i,state,frame)
                    assert after[22:24]==data[22:24] and after[28:32]==data[28:32]
                cycle_states+=1
    # Keep Sonic's pilot colours unchanged in Tails' original ending.
    c=c2();c.w('Game_Mode',32);c.w('Super_Sonic_palette',0xff)
    dry=(ROOT/'art/palettes/SonicAndTails.bin').read_bytes();c.uc.mem_write(c.s['Normal_palette'],dry)
    c.w('Palette_timer',0);c.w('Palette_frame',0x48,2);c.call('PalCycle_SuperTails')
    assert bytes(c.uc.mem_read(c.s['Normal_palette']+4,6))==dry[4:10]
    print(f'161 protected sprite frames, 4 exact-colour Sonic pilot frames, safe DMA tasks, 16 palette loads and {cycle_states} dry/water palette states passed')

if __name__=='__main__':main()
