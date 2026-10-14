"""Resample Sonic 2's SEGA chant (sound/PCM/SEGA.wav) to Flamedriver's playback rate.

Usage: python tools/flamedriver_sega.py [--check]

Writes sound/flamedriver/Sega PCM.bin, as s1_improvements' `s1tools sound sega`
does for Sonic 1. Flamedriver plays the chant from zPlaySEGAPCM, one byte per
loop; the loop takes 245 Z80 cycles plus about 3.3 wait cycles for reading the
byte through the 68000 bus window, and the NTSC Z80 runs at 3579545 Hz.
"""
import argparse, wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'sound' / 'PCM' / 'SEGA.wav'
DESTINATION = ROOT / 'sound' / 'flamedriver' / 'Sega PCM.bin'
SEGA_RATE = 3579545 / (245 + 3.3)


def sega_pcm():
    with wave.open(str(SOURCE)) as source:
        if (source.getnchannels(), source.getsampwidth()) != (1, 1):
            raise ValueError('SEGA.wav must be 8-bit mono')
        rate = source.getframerate()
        samples = source.readframes(source.getnframes())
    step = rate / SEGA_RATE
    count = int((len(samples) - 1) / step) + 1
    out = bytearray()
    for i in range(count):
        pos = i * step
        whole = int(pos)
        frac = pos - whole
        nxt = samples[min(whole + 1, len(samples) - 1)]
        out.append(round(samples[whole] * (1 - frac) + nxt * frac))
    return bytes(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    data = sega_pcm()
    if args.check:
        ok = DESTINATION.exists() and DESTINATION.read_bytes() == data
        print('up to date' if ok else 'stale')
        raise SystemExit(0 if ok else 1)
    DESTINATION.write_bytes(data)
    print('wrote', DESTINATION.relative_to(ROOT), len(data), 'bytes')


if __name__ == '__main__':
    main()
