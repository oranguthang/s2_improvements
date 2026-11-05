"""Regression checks on the built 68000 code; requires unicorn==2.1.4.
Build the ROM first, then run this script with Python 3.
"""
import re
from pathlib import Path
from unicorn import Uc, UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, UC_HOOK_CODE
from unicorn.m68k_const import *

ROOT=Path(__file__).resolve().parents[1]

class CPU:
    cache={}
    def __init__(self, root, rom, lst):
        key=(str(root),rom,lst,(root/rom).stat().st_mtime_ns,(root/lst).stat().st_mtime_ns)
        if key not in self.cache:
            self.cache[key]=((root/rom).read_bytes(),{m[1]:int(m[2],16)&0xffffffff for m in re.finditer(r'\b([\w.]+)\s*:\s*([0-9A-F]+)\s+[-A-Z]',(root/lst).read_text(errors='replace'))})
        self.rom,self.s=self.cache[key]
        self.uc=Uc(UC_ARCH_M68K,UC_MODE_BIG_ENDIAN)
        self.uc.ctl_set_cpu_model(UC_CPU_M68K_M68000)
        self.uc.mem_map(0,0x800000);self.uc.mem_write(0,self.rom)
        self.uc.mem_map(0xFFFF0000,0x10000)
        self.uc.mem_map(0xA00000,0x20000);self.uc.mem_map(0xC00000,0x1000)
        self.uc.reg_write(UC_M68K_REG_SR,0x2700)
    def addr(self,a):return self.s[a] if isinstance(a,str) else a
    def w(self,a,v,n=1):self.uc.mem_write(self.addr(a),(v&((1<<(n*8))-1)).to_bytes(n,'big'))
    def r(self,a,n=1):return int.from_bytes(self.uc.mem_read(self.addr(a),n),'big')
    def reg(self,n,v):self.uc.reg_write(n,v)
    def call(self,name):
        # Keep the test stack out of Underwater_target_palette ($FFFFF000).
        self.reg(UC_M68K_REG_A7,0xFFFFE7F0);self.w(0xFFFFE7F0,0x7f0000,4)
        try:self.uc.emu_start(self.s[name],0x7f0000,count=1000000)
        except Exception as e:raise RuntimeError((name,hex(self.uc.reg_read(UC_M68K_REG_PC)))) from e
        assert self.uc.reg_read(UC_M68K_REG_PC)==0x7f0000,(name,hex(self.uc.reg_read(UC_M68K_REG_PC)))
        # Materialize Unicorn's lazy 68000 CCR through an actual MOVE SR.
        saved=self.uc.reg_read(UC_M68K_REG_D7)
        self.uc.mem_write(0x7f0000,b'\x40\xc7')
        self.uc.emu_start(0x7f0000,0x7f0002,count=1)
        sr=self.uc.reg_read(UC_M68K_REG_D7)
        self.reg(UC_M68K_REG_D7,saved)
        return not bool(sr&4)
    def skip(self,name,callback=None):
        def hook(uc,pc,size,user):
            if callback:callback(self)
            sp=uc.reg_read(UC_M68K_REG_A7)
            uc.reg_write(UC_M68K_REG_PC,self.r(sp,4));uc.reg_write(UC_M68K_REG_A7,sp+4)
        self.uc.hook_add(UC_HOOK_CODE,hook,begin=self.s[name],end=self.s[name])

def c2():return CPU(ROOT,'s2built.bin','s2.lst')

def record(c,version,payload,magic):
    rec=magic+bytes([version,len(payload)])+bytes(payload)
    rec+=sum(rec).to_bytes(2,'big')
    start=c.s.get('SRAM_settings',0x200001)
    for i,b in enumerate(rec):c.w(start+2*i,b)

def main():
    c=c2();c.call('Settings_Defaults');assert c.r('Cheat_super_music')==1
    c.w('Cheat_super_music',0);c.call('Settings_Save');c.w('Cheat_super_music',1)
    c.call('Settings_Load');assert c.r('Cheat_super_music')==0
    payload=[1,1,1,10,1,1,4,3,2]+([2] if 'VS_player2' in c.s else [])
    record(c,1,payload,b'S2DV');c.call('Settings_Load')
    assert c.r('Cheat_super_music')==1 and c.r('Cheat_god_mode')==1
    c=c2();events=[]
    c.skip('PlayMusic',lambda cpu:events.append(cpu.uc.reg_read(UC_M68K_REG_D0)&255))
    c.w('Cheat_super_music',0);c.call('Super_PlayMusic');assert not events
    c.w('Cheat_super_music',1);c.call('Super_PlayMusic');assert events==[c.s['MusID_SuperSonic']]
    print('S2 SUPER MUSIC defaults, SRAM migration, persistence and requests passed')

if __name__=='__main__':main()
