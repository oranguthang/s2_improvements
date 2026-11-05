"""Swimming animation selection and original S3K asset regression checks.
Requires a default built ROM, unicorn==2.1.4 and the S1 source-input bundle.
Pass --bundle PATH when the bundle is not in ../s1_improvements/tools/data.
"""
import argparse,importlib.util
from pathlib import Path
from check_super_music import c2
from unicorn.m68k_const import UC_M68K_REG_A0

ROOT=Path(__file__).resolve().parents[1]


def face_pixels(c,index):
    # Decode the actual ROM's DPLC and 8-byte S2 mapping records. The head
    # must stay on the same pixels while the arms/legs cycle around it.
    table=c.s['DPLC_Tails'];cue=table+c.r(table+index*2,2);tiles=b''
    for n in range(c.r(cue,2)):
        entry=c.r(cue+2+n*2,2);start=c.s['ArtUnc_Tails']+(entry&0xfff)*32
        tiles+=bytes(c.uc.mem_read(start,((entry>>12)+1)*32))
    table=c.s['Map_Tails'];mapping=table+c.r(table+index*2,2);pixels={}
    for n in reversed(range(c.r(mapping,2))):
        entry=mapping+2+n*8;y=c.r(entry);y=y-256 if y&128 else y
        size=c.r(entry+1);w=(size>>2&3)+1;h=(size&3)+1;attr=c.r(entry+2,2)
        x=c.r(entry+6,2);x=x-65536 if x&32768 else x
        for px in range(w*8):
            for py in range(h*8):
                u=w*8-1-px if attr&0x800 else px;v=h*8-1-py if attr&0x1000 else py
                tile=(attr&0x7ff)+(u//8)*h+v//8
                value=tiles[tile*32+(v%8)*4+(u%8)//2]
                colour=(value>>4) if u%2==0 else (value&15)
                if colour:pixels[x+px,y+py]=colour
    return bytes(pixels.get((x,y),0) for y in range(-12,-4) for x in range(0,12))


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--bundle',type=Path,default=ROOT.parent/'s1_improvements/tools/data/source_inputs.zip');args=ap.parse_args()
    c=c2();p=c.s['MainCharacter'];c.reg(UC_M68K_REG_A0,p)
    c.w('Player_mode',1,2);c.w(p+c.s['status'],0x42);c.w(p+c.s['flying_timer'],240)
    for vy,animation in [(0,'AniIDTailsAni_Swim'),(0xff00,'AniIDTailsAni_SwimUp')]:
        c.w(p+c.s['y_vel'],vy,2);c.call('Tails_FlyingAnimation')
        assert c.r(p+c.s['anim'])==c.s[animation]
    c.w(p+c.s['flying_timer'],0);c.call('Tails_FlyingAnimation')
    assert c.r(p+c.s['anim'])==c.s['AniIDTailsAni_SwimTired']
    spec=importlib.util.spec_from_file_location('poses',ROOT/'tools/import_tails_poses.py')
    poses=importlib.util.module_from_spec(spec);spec.loader.exec_module(poses)
    for path,data in poses.generate(args.bundle).items():assert path.read_bytes()==data,path
    # The actual table must select the imported originals at the old stable IDs.
    for name,prefix in [('mappings/sprite/Tails.asm','Map'),('mappings/spriteDPLC/Tails.asm','DPLC')]:
        import re
        table=re.findall(r'mappingsTableEntry.w\s+(\w+)',(ROOT/name).read_text())
        labels=[f'Swim{i}' for i in range(5)]+[f'SwimCarry{i}' for i in range(2)]+[f'SwimTired{i}' for i in range(3)]
        assert table[0x92:0x9c]==[f'{prefix}_Tails_{label}' for label in labels]
    heads=[face_pixels(c,index) for index in range(0x92,0x97)]
    assert any(heads[0]) and all(head==heads[0] for head in heads),'swimming head jitters'
    print('S2 swimming/tired selection and original S3K art/mappings/DPLCs passed')

if __name__=='__main__':main()
