"""Run regression checks on assembled M68000 routines (requires unicorn 2.1.4).

Usage: python tests/test_stage1.py REPOSITORY --baseline BASELINE_DIRECTORY
BASELINE_DIRECTORY must contain s2built.bin and s2.lst from d6b2f27.
This checks CPU/RAM behavior, not a complete VDP or controller electrical model.
"""
from pathlib import Path
import argparse, hashlib, json, re
from unicorn import Uc, UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, UC_HOOK_CODE, UC_HOOK_MEM_READ, UC_HOOK_MEM_WRITE
from unicorn.m68k_const import *

def symbols(path):
    table = path.read_text(errors='replace').split('Symbol Table (* = unused):',1)[1]
    return {m[1]:int(m[2],16)&0xFFFFFFFF for m in
            re.finditer(r'([A-Za-z_][\w.]*)\s*:\s*([0-9A-F]+)\s+[C-](?=\s*\|)',table)}

class CPU:
    def __init__(self, repo):
        self.rom = (repo/'s2built.bin').read_bytes()
        self.s = symbols(repo/'s2.lst')
        self.uc = Uc(UC_ARCH_M68K,UC_MODE_BIG_ENDIAN)
        self.uc.ctl_set_cpu_model(UC_CPU_M68K_M68000)
        self.uc.mem_map(0,0x200000)
        self.uc.mem_write(0,self.rom)
        self.uc.mem_map(0xFFFF0000,0x10000)
        self.uc.mem_map(0x02000000,0x10000)
        self.uc.mem_map(0xC00000,0x1000)
        self.uc.reg_write(UC_M68K_REG_SR,0x2700)
        self.stop = 0x1F0000
    def addr(self, name):
        return self.s[name] if isinstance(name,str) else name
    def write(self,name,value,size=1):
        self.uc.mem_write(self.addr(name),(value&((1<<(8*size))-1)).to_bytes(size,'big'))
    def read(self,name,size=1):
        return int.from_bytes(self.uc.mem_read(self.addr(name),size),'big')
    def call(self,name,obj=None):
        if obj is not None:
            self.uc.reg_write(UC_M68K_REG_A0,self.addr(obj))
        self.uc.reg_write(UC_M68K_REG_A7,0x0200FFE0)
        self.write(0x0200FFE0,self.stop,4)
        try:
            self.uc.emu_start(self.addr(name),self.stop,count=2000000)
        except Exception as e:
            raise RuntimeError(f'{name} at {self.uc.reg_read(UC_M68K_REG_PC):08X}') from e
        assert self.uc.reg_read(UC_M68K_REG_PC)==self.stop, name
    def skip(self,name):
        address = self.s[name]
        def hook(uc,pc,size,user):
            sp=uc.reg_read(UC_M68K_REG_A7)
            uc.reg_write(UC_M68K_REG_PC,self.read(sp,4))
            uc.reg_write(UC_M68K_REG_A7,sp+4)
        self.uc.hook_add(UC_HOOK_CODE,hook,begin=address,end=address)

def sega(repo,baseline):
    def run(path,mutate=False):
        c=CPU(path)
        if mutate:
            c.uc.mem_write(c.s['ArtUnc_Sonic'],b'\xEE'*0x8000)
        obj=c.s['MainCharacter']
        c.write(obj+c.s['subtype'],0x4C)
        c.call('ObjB0_Init',obj)
        start=c.s['Chunk_Table']
        copied=bytes(c.uc.mem_read(start,4*22*32))
        lo,hi=c.s['SegaScreenScaledSpriteDataStart'],c.s['SegaScreenScaledSpriteDataEnd']
        return copied,bytes(c.uc.mem_read(lo,hi-lo))
    before=run(baseline)
    assert before==run(repo),'Sega screen pixels changed'
    assert before==run(repo,True),'Sega screen still depends on player art'
    return {'copied_bytes':len(before[0]),'enlarged_bytes':len(before[1]),
            'baseline_pixels_identical':True,'player_art_mutation_independent':True}

def burnt(repo):
    fires=('ObjID_LavaBubble','ObjID_RisingLava','ObjID_LavaMarker','ObjID_Sol','ObjID_Laser')
    cases=0
    for character in ('ObjID_Sonic','ObjID_Tails'):
        for hazard in (*fires,'ObjID_Spikes','ObjID_Monitor',character):
            c=CPU(repo)
            obj=c.s['MainCharacter']; killer=c.s['Sidekick']+0x80
            c.write(obj+c.s['id'],c.s[character])
            c.write(killer+c.s['id'],c.s[hazard])
            c.uc.reg_write(UC_M68K_REG_A2,killer)
            sounds=[]
            def sound(uc,pc,size,user):
                sounds.append(uc.reg_read(UC_M68K_REG_D0)&0xFFFF)
            addr=c.s['PlaySound']
            c.uc.hook_add(UC_HOOK_CODE,sound,begin=addr,end=addr)
            c.skip('PlaySound')
            c.call('KillCharacter',obj)
            burns=c.s.get('FeatureBurntDeath',1) and character=='ObjID_Sonic' and hazard in fires
            expected='AniIDSonAni_DeathBW' if burns else 'AniIDSonAni_Death'
            assert c.read(obj+c.s['anim'])==c.s[expected],(character,hazard)
            assert c.read(obj+c.s['routine'])==6
            assert c.read(obj+c.s['y_vel'],2)==0xF900
            assert c.read(obj+c.s['x_vel'],2)==c.read(obj+c.s['inertia'],2)==0
            expected_sound='SndID_HurtBySpikes' if hazard=='ObjID_Spikes' else 'SndID_Hurt'
            assert sounds==[c.s[expected_sound]],(character,hazard,sounds)
            cases+=1
    c=CPU(repo);obj=c.s['MainCharacter']
    c.write(obj+c.s['id'],c.s['ObjID_Sonic']);c.write('Debug_placement_mode',1,2)
    c.uc.reg_write(UC_M68K_REG_A2,c.s['Sidekick'])
    before=bytes(c.uc.mem_read(obj,0x40));c.call('KillCharacter',obj)
    assert before==bytes(c.uc.mem_read(obj,0x40)),'Debug kill guard changed'
    return {'death_cases':cases,'debug_guard_passed':True,'tails_uses_normal_death':True,'sounds_preserved':True,
            'burnt_animation':'on' if c.s.get('FeatureBurntDeath',1) else 'off'}

def controllers(repo):
    cases=0
    c=CPU(repo)
    c.uc.mem_map(0xA10000,0x1000)
    ports={c.s[f'HW_Port_{n}_Data']:{'six':False,'raw':0,'extra':0,'low':0,'th':1} for n in (1,2)}
    def write_port(uc,access,address,size,value,user):
        p=ports.get(address)
        if p is not None:
            th=bool(value&0x40)
            if p['th'] and not th:
                p['low']+=1
            p['th']=th
    def read_port(uc,access,address,size,value,user):
        p=ports.get(address)
        if p is None:
            return
        raw=p['raw'];low=p['low']
        if p['th']:
            value=((~raw)&0x30)|((~p['extra'])&15) if p['six'] and low==3 else (~raw)&0x3F
            value|=0x40
        else:
            value=((~raw)>>2)&0x30
            if p['six'] and low==3:
                pass
            elif p['six'] and low==4:
                value|=15
            else:
                value|=(~raw)&3
        uc.mem_write(address,bytes([value]))
    c.uc.hook_add(UC_HOOK_MEM_WRITE,write_port,begin=0xA10000,end=0xA1000F)
    c.uc.hook_add(UC_HOOK_MEM_READ,read_port,begin=0xA10000,end=0xA1000F)
    for types in ((False,False),(True,False),(False,True),(True,True)):
        previous=[0,0];extended=[0,0]
        for raw in range(256):
            wanted=(raw,raw^0xA5);extras=(raw&15,(raw>>4)&15)
            for n,p in enumerate(ports.values()):
                p.update(six=types[n],raw=wanted[n],extra=extras[n],low=0,th=1)
            c.uc.reg_write(UC_M68K_REG_A2,0xFFFF1234)
            c.call('ReadJoypads')
            assert c.uc.reg_read(UC_M68K_REG_A2)==0xFFFF1234
            for n,p in enumerate(ports.values(),1):
                assert c.read(f'Ctrl_{n}_Held')==wanted[n-1],(types,raw,n,'held')
                assert c.read(f'Ctrl_{n}_Press')==(wanted[n-1]&~previous[n-1]&255),(types,raw,n,'pressed')
                expected=(0x80|extras[n-1]) if types[n-1] else 0
                assert c.read(f'Ctrl_{n}_Held_6B')==expected,(types,raw,n,'extended')
                assert c.read(f'Ctrl_{n}_Press_6B')==(expected&~extended[n-1]&15)
                assert p['th'],'TH must finish high'
                previous[n-1]=wanted[n-1];extended[n-1]=expected
            cases+=1
        # The next configuration simulates controller replacement between frames.
        for n in (1,2):
            c.write(f'Ctrl_{n}_Held',0);c.write(f'Ctrl_{n}_Held_6B',0)
    # Explicit unplug: pulled-up ports must release all inputs, including extras.
    for n,p in enumerate(ports.values(),1):
        p.update(six=False,raw=0,extra=0,low=0,th=1)
        c.write(f'Ctrl_{n}_Held_6B',0x8F);c.write(f'Ctrl_{n}_Press_6B',15)
    c.call('ReadJoypads')
    for n in (1,2):
        assert c.read(f'Ctrl_{n}_Held_6B',2)==0
    assert c.s['Ctrl_1']==0xFFFFF604 and c.s['Ctrl_2']==0xFFFFF606
    assert c.s['VDP_Reg1_val']==0xFFFFF60C,'RAM layout moved'
    return {'both_port_frames':cases,'three_and_six_button_mixes_passed':True,
            'up_down_false_detection_rejected':True,'unplug_clears_extra_inputs':True,'original_ram_layout_preserved':True}

def vs_countdown(repo):
    triggers=0
    for option,expected in ((0,0x3C3C),(1,0x5A3C),(2,0)):
        for trigger in ('loc_1922C','loc_192BC','loc_1932E'):
            c=CPU(repo);obj=c.s['MainCharacter']+0x100
            c.write('Two_player_mode',1,2);c.write('VS_countdown_option',option,2)
            c.write('Loser_Time_Left',0x1234,2)
            c.skip('loc_19350');c.skip('PlaySound')
            c.call(trigger,obj)
            assert c.read('Loser_Time_Left',2)==expected,(option,trigger)
            triggers+=1
    # A cycles only on the VS row and remains edge-triggered.
    for row in range(3):
        c=CPU(repo);c.write('Options_menu_box',row)
        for wanted in (1,2,0):
            c.uc.reg_write(UC_M68K_REG_D0,c.s['button_A_mask'])
            c.call('OptionScreen_CycleCountdown')
            assert c.read('VS_countdown_option',2)==(wanted if row==1 else 0)
        c.uc.reg_write(UC_M68K_REG_D0,0);c.call('OptionScreen_CycleCountdown')
        assert c.read('VS_countdown_option',2)==0
    # Draw the actual label into a guarded menu row; no VDP emulation needed.
    for mode in range(3):
        c=CPU(repo);c.write('Options_menu_box',1);c.write('VS_countdown_option',mode,2)
        dst=c.s['Chunk_Table']+22*5*2+2*2
        c.uc.mem_write(dst-2,b'\xAA'*40)
        c.uc.reg_write(UC_M68K_REG_A2,dst);c.uc.reg_write(UC_M68K_REG_D0,0x6000)
        c.call('OptionScreen_DrawCountdown')
        assert c.read(dst-2,2)==0xAAAA and c.read(dst+36,2)==0xAAAA
        name=('TextOptScr_Countdown60','TextOptScr_Countdown90','TextOptScr_CountdownOff')[mode]
        addr=c.s[name];length=c.rom[addr]+1
        expected=b''.join((0x6000+x).to_bytes(2,'big') for x in c.rom[addr+1:addr+1+length])
        assert bytes(c.uc.mem_read(dst,len(expected)))==expected
    # Check late music/expiry behavior, disabled timer and pause for both racers.
    expiry=0
    for remaining in (0,0x0C01,0x0001):
        for racing in (1,2):
            c=CPU(repo);c.write('Two_player_mode',1,2);c.write('Loser_Time_Left',remaining,2)
            c.write('Update_HUD_timer' if racing==1 else 'Update_HUD_timer_2P',1)
            c.write(c.s['MainCharacter']+c.s['id'],c.s['ObjID_Sonic'])
            c.write(c.s['Sidekick']+c.s['id'],c.s['ObjID_Tails'])
            sounds=[]
            def music(uc,pc,size,user):
                sounds.append(uc.reg_read(UC_M68K_REG_D0)&0xFFFF)
            c.uc.hook_add(UC_HOOK_CODE,music,begin=c.s['PlayMusic'],end=c.s['PlayMusic'])
            c.skip('PlayMusic');c.skip('PlaySound');c.call('loc_40F50')
            if remaining==0:
                assert c.read('Loser_Time_Left',2)==0 and not sounds
                assert c.read('Time_Over_flag' if racing==1 else 'Time_Over_flag_2P')==0
            elif remaining==0x0C01:
                assert c.read('Loser_Time_Left',2)==0x0B3C
                assert sounds==[c.s['MusID_Countdown']]
            else:
                assert c.read('Time_Over_flag' if racing==1 else 'Time_Over_flag_2P')==1
                expiry+=1
    c=CPU(repo);c.write('Game_paused',1,2);c.write('Loser_Time_Left',0x0101,2)
    c.call('loc_40F50');assert c.read('Loser_Time_Left',2)==0x0101
    for racing in (1,2):
        for remaining in (0,0x1E3C):
            c=CPU(repo);c.write('Loser_Time_Left',remaining,2)
            c.write('Update_HUD_timer' if racing==1 else 'Update_HUD_timer_2P',1)
            digits=[]
            def number(uc,pc,size,user):
                digits.append(uc.reg_read(UC_M68K_REG_D7)&0xFFFF)
            c.uc.hook_add(UC_HOOK_CODE,number,begin=c.s['loc_40938'],end=c.s['loc_40938'])
            for name in ('DrawSprite_2P_Loop','sub_4092E','sub_4096A','sub_40984','loc_40938'):
                c.skip(name)
            c.call(f'BuildHUD_P{racing}_Continued')
            assert digits==([0,30] if remaining else [0]),(racing,remaining,digits)
    return {'all_three_start_triggers':triggers,'menu_cycle_and_labels_passed':True,
            'music_threshold_preserved':True,'both_racer_expiry_cases':expiry,'off_and_pause_passed':True,
            'inactive_countdown_digits_hidden_for_both_players':True}

def vs_signpost_music(repo):
    # When a racer passes the signpost, the zone music only comes back if the
    # countdown music is playing (12 seconds or less left); an inactive (off)
    # countdown must not restart it.
    checked=0
    for racer in (1,2):
        for remaining,restore in ((0,False),(0x0B10,True),(0x3C3C,False)):
            c=CPU(repo);obj=c.s['MainCharacter']+0x100
            c.write('Two_player_mode',1,2);c.write('VS_countdown_option',2 if remaining==0 else 0,2)
            c.write('Loser_Time_Left',remaining,2);c.write('Level_Music',c.s['MusID_EHZ'],2)
            c.write(obj+c.s['x_pos'],0x1000,2)
            if racer==1:
                c.write('Update_HUD_timer',1);c.write(c.s['MainCharacter']+c.s['x_pos'],0x1010,2)
            else:
                c.write('Update_HUD_timer',0);c.write('Update_HUD_timer_2P',1)
                c.write(c.s['Sidekick']+c.s['x_pos'],0x1010,2)
            sounds=[]
            def music(uc,pc,size,user):
                sounds.append(uc.reg_read(UC_M68K_REG_D0)&0xFFFF)
            c.uc.hook_add(UC_HOOK_CODE,music,begin=c.s['PlayMusic'],end=c.s['PlayMusic'])
            c.skip('PlayMusic');c.skip('PlaySound');c.skip('loc_19350')
            c.call('Obj0D_Main',obj)
            assert c.s['SndID_Signpost'] in sounds,(racer,remaining,sounds)
            assert (c.s['MusID_EHZ'] in sounds)==restore,(racer,remaining,sounds)
            checked+=1
    return {'signpost_music_cases':checked,'off_countdown_keeps_zone_music':True}

def options_layout(repo):
    c=CPU(repo);base=c.s['Chunk_Table'];templates={}
    # OptionScreen_Choices stores limits in pointer bits 24..31. Real M68000
    # ignores those address bits; Unicorn needs explicit mirrored RAM pages.
    table=c.s['OptionScreen_Choices']
    aliases=sorted({(c.rom[table+4*i]<<24)|0xFF0000 for i in range(3)}-{0xFFFF0000})  # $FF is RAM itself
    for address in aliases:c.uc.mem_map(address,0x10000)
    for selected in (True,False):
        offset=0 if selected else 0x160
        c.uc.reg_write(UC_M68K_REG_A0,c.s['MapEng_Options'])
        c.uc.reg_write(UC_M68K_REG_A1,base+offset)
        c.uc.reg_write(UC_M68K_REG_D0,c.s['ArtTile_ArtNem_MenuBox']|(0 if selected else 0x2000))
        c.call('EniDec')
        templates[selected]=bytes(c.uc.mem_read(base+offset,0x160))
    captures=[]
    def upload(uc,pc,size,user):
        src=uc.reg_read(UC_M68K_REG_A1)
        assert uc.reg_read(UC_M68K_REG_D1)==21 and uc.reg_read(UC_M68K_REG_D2)==7
        captures.append(bytes(uc.mem_read(src,0x160)))
    c.uc.hook_add(UC_HOOK_CODE,upload,begin=c.s['PlaneMapToVRAM_H40'],end=c.s['PlaneMapToVRAM_H40'])
    c.skip('PlaneMapToVRAM_H40')
    c.write('Player_option',1,2);c.write('Two_player_items',0,2);c.write('Sound_test_sound',0x2A,2)
    def draw(row,selected):
        c.write('Options_menu_box',row)
        ram=bytes(c.uc.mem_read(0xFFFF0000,0x10000))
        for address in aliases:c.uc.mem_write(address,ram)
        c.call('OptionScreen_DrawSelected' if selected else 'OptionScreen_DrawUnselected')
        block=captures[-1];original=templates[selected]
        for y in range(8):
            for x in range(22):
                if y in (0,6,7) or x in (0,20,21):
                    i=(y*22+x)*2
                    assert block[i:i+2]==original[i:i+2],('damaged box border',row,selected,x,y)
        # VS MODE ITEMS (and PLAYER SELECT once player 2 picks a character in
        # VS) show their choice on row 3 and a second line on row 5
        two_lines=(1,0) if 'VS_player2' in c.s else (1,)
        for y in (3,4,5):
            if (row in two_lines and y==4) or (row not in two_lines and y in (3,5)):
                assert block[y*44:(y+1)*44]==original[y*44:(y+1)*44],('stale text in shared box',row,selected,y)
        if row==0 and 'VS_player2' in c.s:
            names=(('TextOptScr_VSMiles','TextOptScr_VSSonic','TextOptScr_VSKnuckles'))
            addr=c.s[names[c.read('VS_player2',1)]];length=c.rom[addr]+1;assert length==18
            palette=0x6000 if selected else 0
            expected=b''.join((palette+x).to_bytes(2,'big') for x in c.rom[addr+1:addr+1+length])
            assert block[22*5*2+4:22*5*2+40]==expected
        if row==1:
            name=('TextOptScr_Countdown60','TextOptScr_Countdown90','TextOptScr_CountdownOff')[c.read('VS_countdown_option',2)]
            addr=c.s[name];length=c.rom[addr]+1;assert length==18
            palette=0x6000 if selected else 0
            expected=b''.join((palette+x).to_bytes(2,'big') for x in c.rom[addr+1:addr+1+length])
            assert block[22*5*2+4:22*5*2+40]==expected
        return block
    draw(0,True);draw(1,False);draw(2,False)
    # Execute the real shared-template redraw order when selection changes.
    for option in range(3):
        c.write('VS_countdown_option',option,2)
        if 'VS_player2' in c.s:
            c.write('VS_player2',option,1)
        previous=0
        for row in (1,2,0,2,1,0):
            draw(previous,False);draw(row,True);previous=row
    return {'complete_box_redraws':len(captures),'countdown_only_in_vs_box':True,
            'all_borders_and_shadow_preserved':True,'no_stale_choice_rows':True}

def debug(repo):
    entries=0
    for character in ('ObjID_Sonic','ObjID_Tails'):
        for water in (False,True):
            for shoes,super_form in ((False,False),(True,False),(False,True),(True,True)):
                if character=='ObjID_Tails' and super_form:
                    continue
                c=CPU(repo);obj=c.s['MainCharacter']
                c.skip('PlayMusic')
                c.write(obj+c.s['id'],c.s[character])
                c.write(obj+c.s['status'],0x6E if water else 0x2E)
                c.write(obj+c.s['air_left'],5 if water else 30)
                c.write(obj+c.s['speedshoes_time'],100 if shoes else 0,2)
                c.write('Super_Sonic_flag',int(super_form))
                c.write(obj+c.s['x_vel'],0xA00,2);c.write(obj+c.s['y_vel'],0xFC00,2)
                c.write(obj+c.s['inertia'],0xC00,2)
                c.write(obj+c.s['x_pos'],100,2);c.write(obj+c.s['y_pos'],200,2)
                c.write('Camera_Y_pos_bias',8,2);c.write('Camera_Y_pos_bias_P2',0xC8,2)
                c.write('Camera_pan',160,2)
                c.write('Camera_Min_Y_pos',0x20,2);c.write('Camera_Max_Y_pos_target',0x800,2)
                c.write('Debug_placement_mode',1,2);c.write('Game_Mode',c.s['GameModeID_Level'])
                c.write('Player_mode',2 if character=='ObjID_Tails' else 0,2)
                c.call('Debug_Init',obj)
                assert c.read('Camera_Y_pos_bias',2)==c.read('Camera_Y_pos_bias_P2',2)==96
                assert c.read('Camera_pan',2)==0xA0 and c.read(obj+c.s['air_left'])==30
                assert c.read(obj+c.s['status'])&0x42==0,'Water/in-air not reset on entry'
                speed='Tails_top_speed' if character=='ObjID_Tails' else 'Sonic_top_speed'
                expected_top=0xC00 if shoes else (0xA00 if super_form else 0x600)
                assert c.read(speed,2)==expected_top,(character,shoes,super_form)
                assert c.read(obj+c.s['x_vel'],2)==c.read(obj+c.s['y_vel'],2)==c.read(obj+c.s['inertia'],2)==0
                # The tail stays allocated but does not draw/update during placement.
                if character=='ObjID_Tails':
                    tail=c.s['Tails_Tails'];c.write(tail+c.s['parent'],obj,2)
                    before=bytes(c.uc.mem_read(tail,0x40));c.call('Obj05_Main',tail)
                    assert before==bytes(c.uc.mem_read(tail,0x40))
                c.write('Timer_minute',2);c.write('Timer_second',37)
                c.write(obj+c.s['jumping'],1);c.write(obj+c.s['transform_combo_timer'],5)
                c.write(obj+c.s['transform_combo_buttons'],0xC0)
                c.write('Ctrl_1_Press',c.s['button_B_mask'])
                c.call('Debug_ExitDebugMode',obj)
                assert c.read('Debug_placement_mode',2)==0
                assert c.read(obj+c.s['mappings'],4)==c.s['MapUnc_Tails' if character=='ObjID_Tails' else 'MapUnc_Sonic']
                assert c.read(obj+c.s['y_radius'])==(15 if character=='ObjID_Tails' else 19)
                assert c.read(obj+c.s['x_radius'])==9 and c.read(obj+c.s['routine'])==2
                for field in ('jumping','transform_combo_timer','transform_combo_buttons'):
                    assert c.read(obj+c.s[field])==0
                assert c.read('Timer_minute')==2 and c.read('Timer_second')==37
                assert c.read('Update_HUD_score')==c.read('Update_HUD_rings')==1
                assert c.read('Camera_Min_Y_pos',2)==0x20 and c.read('Camera_Max_Y_pos_target',2)==0x800
                entries+=1
    rescue=0
    for name in ('Obj02_Control','Obj02_Hurt','Obj02_Dead'):
        c=CPU(repo);obj=c.s['MainCharacter']
        c.write('Debug_mode_flag',1,2);c.write('Ctrl_1_Press',c.s['button_B_mask'])
        c.write('Control_Locked',1);c.call(name,obj)
        assert c.read('Debug_placement_mode',2)==1 and c.read('Control_Locked')==0
        rescue+=1
    for role in ('MainCharacter','Sidekick'):
        for enabled in (False,True):
            for pressed in (False,True):
                c=CPU(repo);c.write('Debug_mode_flag',int(enabled),2)
                c.write('Ctrl_1_Press',c.s['button_B_mask'] if pressed else 0)
                c.call('Tails_TryEnterDebug',role)
                expected=int(role=='MainCharacter' and enabled and pressed)
                assert c.read('Debug_placement_mode',2)==expected
                assert c.uc.reg_read(UC_M68K_REG_D0)==expected
    # Debug coordinates: a separate overlay whenever debug mode is available
    # in a 1P game (and the sidekick's shield slot is free); SCORE stays.
    for enabled,two_player,shield in ((False,0,0),(True,0,0),(True,1,0),(True,0,1)):
        c=CPU(repo);c.write('Debug_mode_flag',int(enabled),2);c.write('Two_player_mode',two_player,2)
        c.write(c.s['Sidekick']+c.s['id'],c.s['ObjID_Tails'])
        c.write(c.s['Sidekick']+c.s['status_secondary'],1<<c.s['status_secondary.shield'] if shield else 0)
        calls=[]
        def coordinates(uc,pc,size,user):
            calls.append(pc)
        c.uc.hook_add(UC_HOOK_CODE,coordinates,begin=c.s['HudDebug_DrawGlyphs'],end=c.s['HudDebug_DrawGlyphs'])
        c.uc.hook_add(UC_HOOK_CODE,coordinates,begin=c.s['HudDb_XY'],end=c.s['HudDb_XY'])
        c.call('HudUpdate' if not two_player else 'HudDebug_Overlay')
        assert len(calls)==(11 if enabled and not two_player and not shield else 0),(enabled,two_player,shield,len(calls))
    c=CPU(repo);c.skip('RunPLC_ROM');c.skip('PlaySound')
    c.write('Last_star_pole_hit',5);c.write('Last_star_pole_hit_2P',5)
    c.uc.reg_write(UC_M68K_REG_D0,c.s['chemical_plant_zone_act_1'])
    c.call('LevelSelect_StartZone')
    assert c.read('Last_star_pole_hit')==c.read('Last_star_pole_hit_2P')==0
    assert c.read('Life_count')==c.read('Life_count_2P')==3
    c=CPU(repo);c.write('Level_select_zone',0,2)
    count=c.s.get('PlayerOption_Count',3)
    for option in list(range(1,count))+[0]:
        c.write('Ctrl_1_Press',c.s['button_C_mask'])
        c.call('LevSelControls_SwitchSide');assert c.read('Player_option',2)==option
    return {'character_water_powerup_cycles':entries,'tails_hurt_and_death_rescue_cases':rescue,
            'sidekick_entry_rejected':True,'normal_hud_outside_placement':True,
            'level_select_character_cycle_and_checkpoint_reset':True}

def special_stage_state(repo):
    cases=0
    def until(c,start,end):
        def stop(uc,pc,size,user):
            uc.reg_write(UC_M68K_REG_PC,c.stop)
        h=c.uc.hook_add(UC_HOOK_CODE,stop,begin=c.s[end],end=c.s[end])
        try:
            c.call(start)
        finally:
            c.uc.hook_del(h)

    for mode in (0,1,2):
        for shields in (0,1,2,3):
            c=CPU(repo)
            c.write('Player_mode',mode,2);c.write('Player_option',mode,2)
            c.write('Current_ZoneAndAct',c.s['emerald_hill_zone_act_1'],2)
            c.write('Game_Mode',c.s['GameModeID_Level'])
            c.write('Last_star_pole_hit',1);c.write('Saved_Last_star_pole_hit',1)
            c.write('Saved_x_pos',0x800,2);c.write('Saved_y_pos',0x280,2)
            c.write('Saved_Timer',0x00012300,4)
            c.write('Saved_Ring_count',51,2);c.write('Saved_Extra_life_flags',0)
            c.write('Saved_art_tile',0x780,2);c.write('Saved_Solid_bits',0x0C0D,2)
            c.write('Saved_Camera_Max_Y_pos',0x300,2)
            c.write('Ring_count',134,2);c.write('Ring_count_2P',27,2)
            c.write('Extra_life_flags',1);c.write('Extra_life_flags_2P',3)
            c.write('Perfect_rings_left',13,2);c.write('Perfect_rings_flag',0x1200,2)
            c.write('MainCharacter',c.s['ObjID_Tails'] if mode==2 else c.s['ObjID_Sonic'])
            c.write('Sidekick',c.s['ObjID_Tails'] if mode==0 else 0)
            c.write(c.s['MainCharacter']+c.s['status_secondary'],6|(shields&1))
            c.write(c.s['Sidekick']+c.s['status_secondary'],6|((shields>>1)&1))
            c.uc.mem_write(c.s['CNZ_saucer_data'],bytes(range(64)))
            # Populate all dynamic slots: high indexes expose counter/index alias bugs.
            table=c.s['Obj_respawn_data'];dynamic=c.s['Dynamic_Object_RAM']
            total=(c.s['Dynamic_Object_RAM_End']-dynamic)//c.s['object_size']
            expected=bytearray([0x80]*190)
            for i in range(total):
                obj=dynamic+i*c.s['object_size'];index=i+50
                c.write(obj+c.s['id'],c.s['ObjID_Coconuts'])
                c.write(obj+c.s['respawn_index'],index)
                expected[index]=0
            c.write(dynamic+c.s['id'],c.s['ObjID_Explosion']);expected[50]=0x80
            c.write(dynamic+c.s['object_size']+c.s['id'],c.s['ObjID_Explosion'])
            c.write(dynamic+c.s['object_size']+c.s['routine'],2);expected[51]=0x80
            # Monitor and checkpoint states keep bit 0 while alive bit 7 clears.
            c.write(dynamic+2*c.s['object_size']+c.s['id'],c.s['ObjID_Monitor'])
            expected[52]=1
            c.uc.mem_write(table,b'\x80'*190);c.write(table+52,0x81)
            ring=c.s['Ring_Positions'];consume=c.s['Ring_consumption_table']
            c.uc.mem_write(ring,b'\0'*0x600)
            for i,(state,x,y) in enumerate(((0,0,0),(0xFFFF,0x760,0x180),(0x0604,0x780,0x188),(0,0x790,0x190),(0xFFFF,0xFFFF,0))):
                c.write(ring+i*6,state,2);c.write(ring+i*6+2,x,2);c.write(ring+i*6+4,y,2)
            c.uc.mem_write(consume,b'\0'*0x80);c.write(consume,1,2)
            c.write(consume+0x7E,(ring+12)&0xFFFF,2)
            ring_snapshot=bytes(c.uc.mem_read(ring,0x600))
            consumption_snapshot=bytes(c.uc.mem_read(consume,0x80))
            c.uc.reg_write(UC_M68K_REG_D7,0x72)
            c.write('TitleCard',c.s['ObjID_Starpost'])
            c.write(c.s['TitleCard']+c.s['collision_property'],1)
            c.skip('DisplaySprite')
            c.call('Obj79_Star','TitleCard')
            assert c.read('Game_Mode')==c.s['GameModeID_SpecialStage']
            assert c.read('SS_keep_level_state')==1,'star entrance failed to save state'
            assert c.uc.reg_read(UC_M68K_REG_D7)==0x72,'RunObjects loop register clobbered'
            assert bytes(c.uc.mem_read(table,190))==bytes(expected),'alive/dead flags'
            assert c.read('Saved_Ring_count',2)==51,'checkpoint snapshot overwritten'
            # Real SpecialStage preamble performs RAM clears; skip VDP/sound waits.
            for name in ('PlaySound','PlayMusic','Pal_FadeToWhite'):
                c.skip(name)
            until(c,'SpecialStage','ssInitTableBuffers')
            assert bytes(c.uc.mem_read(table,190))==bytes(expected),'Special Stage overwrote objects'
            assert bytes(c.uc.mem_read(ring,0x600))==ring_snapshot,'Special Stage overwrote rings'
            assert bytes(c.uc.mem_read(consume,0x80))==consumption_snapshot
            c.call('SSInitPalAndData')
            assert c.read('Ring_count',2)==c.read('Ring_count_2P',2)==0
            assert c.read('SS_keep_level_state')==1
            # Mimic rings/score/lives obtained in the Special Stage.
            c.write('Ring_count',89,2);c.write('Ring_count_2P',45,2)
            c.write('Life_count',8);c.write('Life_count_2P',7)
            c.write('Score',23450,4);c.write('Score_2P',12340,4)
            c.write('Perfect_rings_flag',0xFFFF,2)
            c.write('Game_Mode',c.s['GameModeID_Level'])
            c.call('SS_ValidateLevelReturn');assert c.read('SS_keep_level_state')==1
            # Execute actual level clearing, checkpoint load, player init and manager init.
            for name in ('ClearPLC','Pal_FadeToBlack','ClearScreen','LoadTitleCard',
                         'LoadPLC','PalLoad_Now','PalLoad_ForFade','WaitForVint','RunPLC_RAM',
                         'Hud_Base','DeformBgLayer','LoadZoneTiles','loadZoneBlockMaps',
                         'LoadAnimatedBlocks','DrawInitialBG','ConvertCollisionArray',
                         'LoadCollisionIndexes','WaterEffects','BuildSprites','AniArt_Load'):
                if name in c.s:
                    c.skip(name)
            # Renderer/object behavior is tested separately; keep title-card loop finite here.
            c.skip('RunObjects')
            until(c,'Level_ClrRam','Level_MainLoop')
            assert c.read('SS_keep_level_state')==0,'return snapshot not consumed'
            assert c.read('Ring_count',2)==134 and c.read('Ring_count_2P',2)==27
            assert c.read('Extra_life_flags')==1 and c.read('Extra_life_flags_2P')==3
            assert c.read('Perfect_rings_left',2)==13 and c.read('Perfect_rings_flag',2)==0x1200
            assert c.read('Life_count')==8 and c.read('Life_count_2P')==7
            assert c.read('Score',4)==23450 and c.read('Score_2P',4)==12340
            assert c.read(c.s['MainCharacter']+c.s['status_secondary'])==(shields&1)
            assert c.read('Sonic_Shield')==(c.s['ObjID_Shield'] if shields&1 else 0)
            if mode==0:
                assert c.read(c.s['Sidekick']+c.s['status_secondary'])==((shields>>1)&1)
                assert c.read('Tails_Shield')==(c.s['ObjID_Shield'] if shields&2 else 0)
            else:
                assert c.read('Tails_Shield')==0,'shield attached to absent sidekick'
            assert c.read(ring+6,2)==c.read(ring+12,2)==0xFFFF
            assert c.read(ring+18,2)==0 and c.read(ring+20,2)==0x790
            assert bytes(c.uc.mem_read(consume,0x80))==b'\0'*0x80
            assert c.read('Ring_start_addr',2)==(ring+6)&0xFFFF
            assert c.read('Ring_end_addr',2)==(ring+24)&0xFFFF
            assert bytes(c.uc.mem_read(c.s['CNZ_saucer_data'],64))==bytes(range(64))
            assert c.read(table+50)==c.read(table+51)==0x80,'exploding enemies revived'
            assert c.read(table+52)&1,'destroyed monitor lost its state'
            # Ordinary death: level clear consumes no stale shield/ring/object snapshot.
            until(c,'Level_ClrRam','Level_MainLoop')
            expected_rings=51 if c.s.get('FeatureLamppostRings',1) else 0
            assert c.read('Ring_count',2)==expected_rings,'ordinary checkpoint ring behavior changed'
            assert c.read('Sonic_Shield')==c.read('Tails_Shield')==0
            assert c.read(ring+6,2)==0,'normal death failed to reload rings'
            assert bytes(c.uc.mem_read(c.s['CNZ_saucer_data'],64))==b'\0'*64
            assert c.read(table+50)==c.read(table+51)==0,'ordinary death kept killed enemies'
            cases+=1
    # Refuse state at another act/start, demos, VS, and explicit Level Select.
    for invalid in ('zone','checkpoint','demo','vs','level_select'):
        c=CPU(repo);c.write('SS_keep_level_state',1);c.write('Last_star_pole_hit',1)
        if invalid=='zone':c.write('Current_ZoneAndAct',1,2)
        if invalid=='checkpoint':c.write('Last_star_pole_hit',0)
        if invalid=='demo':c.write('Demo_mode_flag',1,2)
        if invalid=='vs':c.write('Two_player_mode',1,2)
        if invalid=='level_select':
            c.skip('RunPLC_ROM');c.skip('PlaySound');c.call('LevelSelect_StartZone')
        else:c.call('SS_ValidateLevelReturn')
        assert c.read('SS_keep_level_state')==0,invalid
    # All 63 slots, sparse entries, invalid address and a wrong count remain bounded.
    c=CPU(repo);ring=c.s['Ring_Positions'];consume=c.s['Ring_consumption_table']
    c.write(consume,0xFFFF,2)
    for slot in range(63):c.write(consume+2+slot*2,(ring+6*(slot+1))&0xFFFF,2)
    c.write(consume+2,0xFFFF,2)
    c.call('RingsManager_Setup_SSReturn')
    assert bytes(c.uc.mem_read(consume,0x80))==b'\0'*0x80
    for i in range(2,64):assert c.read(ring+i*6,2)==0xFFFF
    # Shield slots are actually run under the level title-card flag.
    for game_mode in ('level_title','special','normal'):
        c=CPU(repo);c.write('Game_Mode',c.s['GameModeID_Level']|(1<<c.s['GameModeFlag_TitleCard']) if game_mode=='level_title' else c.s['GameModeID_SpecialStage'] if game_mode=='special' else c.s['GameModeID_Level'])
        c.write('Sonic_Shield',c.s['ObjID_Shield'])
        c.write(c.s['Sonic_Shield']+c.s['parent'],c.s['MainCharacter'],2)
        c.write(c.s['MainCharacter']+c.s['status_secondary'],1)
        calls=[]
        def shield(uc,pc,size,user):calls.append(pc)
        c.uc.hook_add(UC_HOOK_CODE,shield,begin=c.s['Obj38'],end=c.s['Obj38'])
        c.skip('Obj38');c.call('RunObjects')
        assert bool(calls)==(game_mode!='special')
    return {'return_and_ordinary_death_cycles':cases,'both_player_shields_and_rings':True,
            'destroyed_enemies_and_monitors_preserved':True,'all_dynamic_slots_visited':True,
            'special_stage_ram_clears_executed':True,'ring_pointers_reinitialized':True,
            'sparse_full_ring_consumption_table_bounded':True,'stale_snapshot_rejections':5,
            'title_card_shield_slots_run':True,'special_stage_rewards_preserved':True}

def homing_attack(repo):
    """Jump Dash follows the D-pad; the Homing Attack aims at the upper third of the target."""
    import math
    def run(held=0,facing_left=False,target=None,used=False):
        c=CPU(repo); obj=c.s['MainCharacter']; s=c.s
        c.write(obj+s['id'],s['ObjID_Sonic'])
        c.write(obj+s['x_pos'],0x1000,2); c.write(obj+s['y_pos'],0x300,2)
        c.write(obj+s['status'],0x06|(1 if facing_left else 0))
        if used:
            c.write(obj+s['homing_attack_byte'],1<<s['homing_attack_flag'])
        c.write('Ctrl_1_Logical',held); c.write('Ctrl_1_Press_Logical',s['button_A_mask'])
        if target:
            dx,dy,size=target; o=s['Dynamic_Object_RAM']
            c.write(o,s['ObjID_Buzzer']); c.write(o+s['collision_flags'],size)
            c.write(o+s['x_pos'],0x1000+dx,2); c.write(o+s['y_pos'],0x300+dy,2)
        c.skip('PlaySound')
        c.call('Sonic_HomingAttack',obj)
        sw=lambda v:v-0x10000 if v&0x8000 else v
        return c,sw(c.read(obj+s['x_vel'],2)),sw(c.read(obj+s['y_vel'],2)),c.read(obj+s['status'])&1
    c,xv,yv,left=run()
    assert (xv,yv,left)==(0x800,0,0),('jump dash right',xv,yv)
    c,xv,yv,left=run(held=c.s['button_left_mask'])
    assert (xv,yv,left)==(-0x800,0,1),('d-pad left',xv,yv,left)
    c,xv,yv,left=run(held=c.s['button_right_mask'],facing_left=True)
    assert (xv,yv,left)==(0x800,0,0),('d-pad right',xv,yv,left)
    c,xv,yv,left=run(used=True)
    assert (xv,yv)==(0,0),'second air dash in one jump'
    c,xv,yv,left=run(target=(-0x60,0x20,0x0B))
    assert (xv,yv)==(0x800,0),'target behind Sonic was chosen'
    # A low target: aim at y - 2h/3, not at its origin.
    size=0x01  # half-height $14
    h=c.rom[c.s['Touch_Sizes']+2*size+1]
    aim=0x20-(2*h)//3
    c,xv,yv,left=run(target=(0x60,0x20,size))
    got=math.atan2(yv,xv); want=math.atan2(aim,0x60); centre=math.atan2(0x20,0x60)
    assert abs(got-want)<0.05 and abs(got-want)<abs(got-centre),(xv,yv,aim)
    c,xv,yv,left=run(held=c.s['button_left_mask'],target=(-0x60,0x20,size))
    assert xv<0 and abs(math.atan2(yv,-xv)-want)<0.05,('target on the left after d-pad left',xv,yv)
    return {'jump_dash_follows_dpad':True,'one_dash_per_jump':True,'targets_ahead_only':True,
            'aims_at_upper_third':True}

def settings_sram(repo):
    """Settings record in odd-byte SRAM: defaults, round trip, checksum and value clamping."""
    def cpu():
        c=CPU(repo)
        c.uc.mem_map(0x200000,0x10000); c.uc.mem_write(0x200000,bytes([0xFF])*0x10000)
        c.uc.mem_map(0xA13000,0x1000)
        return c
    fields=['Level_select_flag','Debug_options_flag','Cheat_all_emeralds','Cheat_super_rings',
            'Cheat_ring_drain','Cheat_god_mode']
    words=['Player_option','Two_player_items','VS_countdown_option']
    extra=['VS_player2'] if 'VS_player2' in symbols(repo/'s2.lst') else []	# FeatureKnuckles
    def values(c):
        return [c.read(f) for f in fields]+[c.read(w,2) for w in words]+[c.read(f) for f in extra]
    defaults=[0,0,0,50,1,0,0,0,0]+[0]*len(extra)
    c=cpu(); c.call('Settings_Load')
    assert values(c)==defaults,('cold defaults',values(c))
    want=[1,1,1,10,1,1,2,3,2]+[2]*len(extra)
    for f,v in zip(fields+words+extra,want):
        c.write(f,v,2 if f in words else 1)
    c.call('Settings_Save')
    sram=bytes(c.uc.mem_read(0x200000,0x40))
    assert sram[1:8:2]==b'S2DV',sram[:16].hex()
    record=sram
    for f in fields+extra: c.write(f,0)
    for w in words: c.write(w,0,2)
    c.call('Settings_Load')
    assert values(c)==want,('round trip',values(c))
    assert c.read('Slow_motion_flag')==1,'level select unlock without slow motion'
    # A corrupted byte makes the whole record invalid.
    c=cpu(); c.uc.mem_write(0x200000,record); c.uc.mem_write(0x200001+2*9,bytes([0x32]))
    c.call('Settings_Load')
    assert values(c)==defaults,('bad checksum',values(c))
    # Out-of-range values are clamped; zero rings turn the drain off.
    c=cpu()
    for f,v in zip(fields+words+extra,[7,2,9,33,5,3,9,8,7,3]):
        c.write(f,v,2 if f in words else 1)
    c.call('Settings_Normalize')
    assert values(c)==defaults,('clamp',values(c))
    c.write('Cheat_super_rings',0); c.write('Cheat_ring_drain',1); c.call('Settings_Normalize')
    assert c.read('Cheat_ring_drain')==0,'drain left on with zero rings'
    return {'cold_defaults':True,'round_trip':True,'checksum_rejects_damage':True,'values_clamped':True}

def god_mode(repo):
    """GOD MODE: normal 1P protection, with only physical P1 protected in VS."""
    def cpu(god=1,two_player=0,slot='MainCharacter',character='sonic'):
        c=CPU(repo); obj=c.s[slot]
        c.write(obj+c.s['id'],c.s['ObjID_Tails' if character=='tails' else 'ObjID_Sonic'])
        c.write(obj+c.s['routine'],2)
        if character=='knuckles':
            c.write('Main_character' if slot=='MainCharacter' else 'Player2_character',1)
        c.write(obj+c.s['x_pos'],0x200,2); c.write(obj+c.s['y_pos'],0x100,2)
        c.write('Cheat_god_mode',god); c.write('Two_player_mode',two_player,2)
        c.write('Ring_count',5,2); c.write('Ring_count_2P',5,2)
        c.write('Camera_Max_Y_pos',0x300,2); c.write('Camera_Max_Y_pos_target',0x300,2)
        hazard=c.s['Sidekick']+0x80
        c.write(hazard+c.s['x_pos'],0x210,2); c.uc.reg_write(UC_M68K_REG_A2,hazard)
        for name in ('PlaySound','PlayMusic'):
            c.skip(name)
        return c,obj
    sw=lambda v:v-0x10000 if v&0x8000 else v
    c,obj=cpu(); c.call('HurtCharacter',obj)
    assert c.read(obj+c.s['routine'])==2 and c.read('Ring_count',2)==5,'hurt despite GOD MODE'
    c,obj=cpu(god=0); c.call('HurtCharacter',obj)
    assert c.read(obj+c.s['routine'])==4,'normal hurt changed'
    c,obj=cpu(); c.call('KillCharacter',obj)
    assert c.read(obj+c.s['routine'])==2 and c.read(obj+c.s['y_pos'],2)==0x100,'killed despite GOD MODE'
    c,obj=cpu(); c.write(obj+c.s['y_pos'],0x300+224+20,2); c.write(obj+c.s['routine'],4)
    c.call('KillCharacter',obj)
    assert c.read(obj+c.s['y_pos'],2)==0x300+224 and sw(c.read(obj+c.s['y_vel'],2))==-0xA00,'no pit bounce'
    assert c.read(obj+c.s['routine'])==2 and c.read(obj+c.s['status'])&2,'pit bounce must leave the player airborne in control'
    vs_cases=0
    for character in ('sonic','tails','knuckles'):
        for slot in ('MainCharacter','Sidekick'):
            for action in ('HurtCharacter','KillCharacter'):
                c,obj=cpu(two_player=1,slot=slot,character=character)
                c.call(action,obj)
                expected=2 if slot=='MainCharacter' else (4 if action=='HurtCharacter' else 6)
                assert c.read(obj+c.s['routine'])==expected,(character,slot,action)
                if slot=='MainCharacter':
                    assert c.read('Ring_count',2)==5
                vs_cases+=1
    # P1 Tails' VS wrapper has exchanged the two sets of camera bounds.
    c,obj=cpu(two_player=1,character='tails')
    c.write('P2_context_active',1); c.write('Camera_Max_Y_pos',0x900,2)
    c.write('Tails_Max_Y_pos',0x300,2); c.write(obj+c.s['y_pos'],0x300+224+20,2)
    c.call('KillCharacter',obj)
    assert c.read(obj+c.s['y_pos'],2)==0x300+224
    assert sw(c.read(obj+c.s['y_vel'],2))==-0xA00 and c.read(obj+c.s['routine'])==2
    # Breathing has the character in a2 while a0 is the separate bubble object.
    for slot in ('MainCharacter','Sidekick'):
        c,obj=cpu(two_player=1,slot=slot)
        bubble=c.s['Sonic_BreathingBubbles' if slot=='MainCharacter' else 'Tails_BreathingBubbles']
        c.write(bubble+c.s['obj0a_character'],obj,4)
        c.write(obj+c.s['status'],1<<c.s['status.player.underwater'])
        c.write(obj+c.s['air_left'],20)
        c.skip('Obj0A_MakeBubbleMaybe')
        c.call('Obj0A_Countdown',bubble)
        assert c.read(obj+c.s['air_left'])==(30 if slot=='MainCharacter' else 19),slot
    # P1's capped timer must not also time out player 2, whose clock still runs.
    for p2_expired in (False,True):
        c,obj=cpu(two_player=1)
        side=c.s['Sidekick']; c.write(side+c.s['id'],c.s['ObjID_Tails'])
        c.write(side+c.s['routine'],2)
        c.write('Update_HUD_timer',1); c.write('Update_HUD_timer_2P',1)
        c.write('Timer',0x00093B3B,4)
        c.write('Timer_2P',0x00093B3B if p2_expired else 0x00000100,4)
        c.call('HudUpdate')
        assert c.read('Timer',4)==0x00093B3B and c.read('Time_Over_flag')==0
        assert c.read(obj+c.s['routine'])==2
        assert c.read(side+c.s['routine'])==(6 if p2_expired else 2)
        assert c.read('Time_Over_flag_2P')==int(p2_expired)
        if not p2_expired:
            assert c.read('Timer_2P',4)==0x00000101
    c,obj=cpu(two_player=1); c.write('Update_HUD_timer',1)
    c.call('TimeOver0')
    assert c.read('Update_HUD_timer')==1 and c.read('Time_Over_flag')==0
    c,obj=cpu(two_player=1); c.write('Demo_mode_flag',1,2)
    c.call('KillCharacter',obj)
    assert c.read(obj+c.s['routine'])==6,'GOD MODE enabled in a title demo'
    return {'no_damage':True,'no_death':True,'pit_bounce':True,'vs_damage_death_cases':vs_cases,
            'vs_player2_unprotected':True,'vs_tails_camera_context':True,
            'vs_air_is_player_specific':True,'vs_timers_are_independent':True,'disabled_in_demos':True}

def extra_lives(repo):
    """Rings award a life at every 100 (FeatureExtraLives) or only at 100 and 200 (original)."""
    every=bool(symbols(repo/'s2.lst').get('FeatureExtraLives',0))
    def collect(rings,flags):
        c=CPU(repo); c.skip('PlaySound2')
        c.write('Ring_count',rings-1,2); c.write('Extra_life_flags',flags); c.write('Life_count',3)
        c.call('CollectRing_1P')
        return c.read('Life_count')-3,c.read('Extra_life_flags')
    if symbols(repo/'s2.lst').get('FeatureInfiniteLives',0):
        assert collect(100,0)[0]==0,'a ring life with infinite lives'
        return {'every_hundred':'infinite lives','thresholds_checked':True}
    lives=[collect(n,f)[0] for n,f in ((99,0),(100,0),(200,1 if every else 2),(300,2 if every else 6),(400,3 if every else 6))]
    assert lives==([0,1,1,1,1] if every else [0,1,1,0,0]),lives
    if every:
        assert collect(300,3)==(0,3),'a hundred rewarded twice'
        assert collect(100,0)==(1,1),'no life after losing the rings'
    return {'every_hundred':'on' if every else 'off','thresholds_checked':True}

def invincibility_flash(repo):
    """The invincibility stars blink during the last two seconds."""
    def shown(time,frame):
        c=CPU(repo); star=c.s['Sidekick']+0x80; player=c.s['MainCharacter']
        c.write(star+c.s['parent'],player&0xFFFF,2); c.write(player+c.s['invincibility_time'],time,2)
        c.write('Level_frame_counter',frame,2)
        calls=[]
        c.uc.hook_add(UC_HOOK_CODE,lambda uc,pc,size,user:calls.append(pc),begin=c.s['DisplaySprite3'],end=c.s['DisplaySprite3'])
        c.skip('DisplaySprite3'); c.call('InvStars_Display',star)
        return bool(calls)
    assert shown(600,4) and shown(121,4),'stars hidden too early'
    assert shown(120,0) and not shown(120,4) and not shown(1,5),'no blink in the last two seconds'
    return {'blinks_last_two_seconds':True}

def fast_sound_test(repo):
    """Sound tests: A steps ahead by $10, B+A back by $10 (FeatureFastSoundTest)."""
    back=bool(symbols(repo/'s2.lst').get('FeatureFastSoundTest',0))
    def levsel(held):
        c=CPU(repo); c.skip('PlayMusic')
        c.call('LevelSelect_GetPage'); last=c.read(c.uc.reg_read(UC_M68K_REG_A2)+c.s['levselpage_last'],2)
        c.write('Level_select_zone',last,2); c.write('Sound_test_sound',0x25,2)
        c.write('Ctrl_1_Press',c.s['button_A_mask']); c.write('Ctrl_1_Held',c.s['button_A_mask']|held)
        c.call('LevSelControls_CheckLR')
        return c.read('Sound_test_sound',2)
    def options(held):
        c=CPU(repo); c.skip('PlayMusic')
        c.write('Options_menu_box',2); c.write('Sound_test_sound',0x25,2)
        c.write('Ctrl_1_Press',c.s['button_A_mask']); c.write('Ctrl_1_Held',c.s['button_A_mask']|held)
        c.call('OptionScreen_Controls')
        return c.read('Sound_test_sound',2)
    b=CPU(repo).s['button_B_mask']
    assert levsel(0)==0x35 and options(0)==0x35,'A no longer steps ahead by $10'
    want=0x15 if back else 0x35
    assert levsel(b)==want and options(b)==want,(levsel(b),options(b))
    return {'a_steps_ahead':True,'b_a_steps_back':'on' if back else 'off'}

def infinite_lives(repo):
    """FeatureInfiniteLives: 1-up monitors give 10 rings in 1P games; VS keeps its lives."""
    def one_up(two_player):
        c=CPU(repo); c.skip('PlayMusic'); c.skip('PlaySound2')
        c.write('Two_player_mode',two_player,2); c.write('Ring_count',5,2); c.write('Life_count',3)
        c.uc.reg_write(UC_M68K_REG_A1,c.s['MainCharacter']); c.uc.reg_write(UC_M68K_REG_A2,c.s['Monitors_Broken'])
        c.call('sonic_1up')
        return c.read('Life_count'),c.read('Ring_count',2)
    assert one_up(0)==(3,15),one_up(0)
    assert one_up(1)==(4,5),one_up(1)
    return {'one_up_gives_rings':True,'vs_keeps_lives':True}

def title_palette(repo):
    def setup():
        c=CPU(repo)
        c.write(c.s['IntroSonic']+c.s['obj0e_music_playing'],1)
        c.write('TitleScreenPaletteChanger3',c.s['ObjID_TtlScrPalChanger'])
        c.call('ObjC9','TitleScreenPaletteChanger3')
        return c
    def tick(c):
        if c.read('TitleScreenPaletteChanger3'):
            c.call('ObjC9','TitleScreenPaletteChanger3')
    def palette(c):return bytes(c.uc.mem_read(c.s['Normal_palette_line4'],32))
    c=setup()
    expected=c.rom[c.s['Pal_1342C']:c.s['Pal_1342C']+32]
    for _ in range(40):tick(c)
    assert palette(c)==expected
    for player in (1,2):
        for frame in range(33):
            c=setup()
            for _ in range(frame):tick(c)
            c.write(f'Ctrl_{player}_Press',0x80)
            c.call('TitleScreen_SetFinalState','IntroSonic')
            assert palette(c)==expected
            assert c.read(f'Ctrl_{player}_Press')==0
            for _ in range(40):tick(c)
            assert palette(c)==expected
    c=setup();before=palette(c);c.call('TitleScreen_SetFinalState','IntroSonic')
    assert palette(c)==before and c.read('TitleScreenPaletteChanger3')!=0
    return {'start_timing_cases':66,'palette_corruption_cases':0,'ordinary_fade_and_no_start_passed':True}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('repo',type=Path)
    parser.add_argument('--baseline',type=Path,required=True)
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    results={'sega':sega(args.repo,args.baseline)}
    results['title_palette']=title_palette(args.repo)
    if 'KillCharacter_SetBurntAnimation' in symbols(args.repo/'s2.lst'):
        results['burnt_death']=burnt(args.repo)
    if 'Ctrl_1_Held_6B' in symbols(args.repo/'s2.lst'):
        results['controllers']=controllers(args.repo)
    if 'VS_StartCountdown' in symbols(args.repo/'s2.lst'):
        results['vs_countdown']=vs_countdown(args.repo)
        results['vs_signpost_music']=vs_signpost_music(args.repo)
        results['options_layout']=options_layout(args.repo)
    if symbols(args.repo/'s2.lst').get('FeatureHomingAttack',0):
        results['homing_attack']=homing_attack(args.repo)
    if 'Debug_PreparePlayer' in symbols(args.repo/'s2.lst'):
        results['debug']=debug(args.repo)
    if symbols(args.repo/'s2.lst').get('FeatureSpecialStageState',0):
        results['special_stage_state']=special_stage_state(args.repo)
    if 'Settings_Load' in symbols(args.repo/'s2.lst'):
        results['settings_sram']=settings_sram(args.repo)
    if 'Cheat_GodModeActive' in symbols(args.repo/'s2.lst'):
        results['god_mode']=god_mode(args.repo)
    results['extra_lives']=extra_lives(args.repo)
    if 'InvStars_Display' in symbols(args.repo/'s2.lst'):
        results['invincibility_flash']=invincibility_flash(args.repo)
    results['fast_sound_test']=fast_sound_test(args.repo)
    if symbols(args.repo/'s2.lst').get('FeatureInfiniteLives',0):
        results['infinite_lives']=infinite_lives(args.repo)
    results['rom_sha256']=hashlib.sha256((args.repo/'s2built.bin').read_bytes()).hexdigest()
    if args.report:
        args.report.write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(results,indent=2))

if __name__=='__main__':
    main()
