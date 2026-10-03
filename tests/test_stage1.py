"""Run regression checks on assembled M68000 routines (requires unicorn 2.1.4).

Usage: python tests/test_stage1.py REPOSITORY --baseline BASELINE_DIRECTORY
BASELINE_DIRECTORY must contain s2built.bin and s2.lst from d6b2f27.
This checks CPU/RAM behavior, not a complete VDP or controller electrical model.
"""
from pathlib import Path
import argparse, hashlib, json, re
from unicorn import Uc, UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, UC_HOOK_CODE
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

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('repo',type=Path)
    parser.add_argument('--baseline',type=Path,required=True)
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    results={'sega':sega(args.repo,args.baseline)}
    results['rom_sha256']=hashlib.sha256((args.repo/'s2built.bin').read_bytes()).hexdigest()
    if args.report:
        args.report.write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(results,indent=2))

if __name__=='__main__':
    main()
