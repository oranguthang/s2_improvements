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
            self.uc.emu_start(self.addr(name),self.stop,count=250000)
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
            expected='AniIDSonAni_DeathBW' if character=='ObjID_Sonic' and hazard in fires else 'AniIDSonAni_Death'
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
    return {'death_cases':cases,'debug_guard_passed':True,'tails_uses_normal_death':True,'sounds_preserved':True}

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

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('repo',type=Path)
    parser.add_argument('--baseline',type=Path,required=True)
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    results={'sega':sega(args.repo,args.baseline)}
    if 'KillCharacter_SetBurntAnimation' in symbols(args.repo/'s2.lst'):
        results['burnt_death']=burnt(args.repo)
    if 'Ctrl_1_Held_6B' in symbols(args.repo/'s2.lst'):
        results['controllers']=controllers(args.repo)
    results['rom_sha256']=hashlib.sha256((args.repo/'s2built.bin').read_bytes()).hexdigest()
    if args.report:
        args.report.write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(results,indent=2))

if __name__=='__main__':
    main()
