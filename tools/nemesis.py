"""Nemesis decompression and table-reusing recompression (from s1_improvements' s1tools)."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Code:
    palette: int
    count: int
    bits: int
    length: int


@dataclass(frozen=True)
class Header:
    tiles: int
    xor: bool
    payload_start: int
    codes: tuple[Code, ...]


def parse_header(blob: bytes) -> Header:
    if len(blob) < 4:
        raise ValueError("Nemesis file is too short")
    word = int.from_bytes(blob[:2], "big")
    tiles = word & 32767
    if not tiles:
        raise ValueError("Nemesis file has no tiles")
    cursor = 2
    palette = None
    codes = []
    while cursor < len(blob):
        entry = blob[cursor]
        cursor += 1
        if entry == 255:
            break
        if entry & 128:
            palette = entry & 15
            continue
        if palette is None or cursor >= len(blob):
            raise ValueError("Malformed Nemesis code table")
        length = entry & 15
        if not 1 <= length <= 8:
            raise ValueError("Invalid Nemesis code length")
        bits = blob[cursor] & (1 << length) - 1
        cursor += 1
        codes.append(Code(palette, (entry >> 4 & 7) + 1, bits, length))
    else:
        raise ValueError("Unterminated Nemesis code table")
    for first in codes:
        for second in codes:
            if first is second:
                continue
            if (
                first.length <= second.length
                and first.bits == second.bits >> second.length - first.length
            ):
                raise ValueError("Overlapping Nemesis codes")
        if first.length >= 6 and first.bits >> first.length - 6 == 63:
            raise ValueError("Nemesis code overlaps inline data")
    return Header(tiles, bool(word & 32768), cursor, tuple(codes))


class BitReader:
    def __init__(self, blob: bytes, start: int):
        self.blob = blob
        self.bit = start * 8

    def read(self, count: int) -> int:
        value = 0
        for _ in range(count):
            if self.bit >= len(self.blob) * 8:
                raise ValueError("Truncated Nemesis pixel stream")
            value = value << 1 | self.blob[self.bit // 8] >> 7 - self.bit % 8 & 1
            self.bit += 1
        return value

    def peek(self, count: int) -> int:
        saved = self.bit
        try:
            return self.read(count)
        except ValueError:
            return -1
        finally:
            self.bit = saved


def decode(blob: bytes) -> bytes:
    header = parse_header(blob)
    reader = BitReader(blob, header.payload_start)
    lookup = {(code.length, code.bits): code for code in header.codes}
    pixels = bytearray()
    pixel_count = header.tiles * 64
    while len(pixels) < pixel_count:
        if reader.peek(6) == 63:
            reader.read(6)
            count = reader.read(3) + 1
            palette = reader.read(4)
        else:
            bits = 0
            for length in range(1, 9):
                bits = bits << 1 | reader.read(1)
                code = lookup.get((length, bits))
                if code:
                    count, palette = (code.count, code.palette)
                    break
            else:
                raise ValueError("Unknown Nemesis pixel code")
        if len(pixels) + count > pixel_count:
            raise ValueError("Nemesis run extends beyond tile count")
        pixels.extend([palette] * count)
    raw = bytearray(pixels[i] << 4 | pixels[i + 1] for i in range(0, len(pixels), 2))
    if header.xor:
        for index in range(4, len(raw)):
            raw[index] ^= raw[index - 4]
    return bytes(raw)


def encode_with_table(original: bytes, raw: bytes) -> bytes:
    header = parse_header(original)
    if len(raw) != header.tiles * 32:
        raise ValueError("Raw art size differs from the original tile count")
    pixels = [nibble for byte in raw for nibble in (byte >> 4, byte & 15)]
    by_run: dict[tuple[int, int], Code] = {}
    for code in header.codes:
        key = (code.palette, code.count)
        if key not in by_run or code.length < by_run[key].length:
            by_run[key] = code
    total = len(pixels)
    costs = [0] * (total + 1)
    choices: list[tuple[int, Code | None] | None] = [None] * total
    for position in range(total - 1, -1, -1):
        color = pixels[position]
        best = (1 << 30, 0, None)
        for count in range(1, min(8, total - position) + 1):
            if pixels[position + count - 1] != color:
                break
            code = by_run.get((color, count))
            bit_length = code.length if code else 13
            candidate = (bit_length + costs[position + count], -count)
            if candidate < best[:2]:
                best = (*candidate, code)
                choices[position] = (count, code)
        costs[position] = best[0]
    payload = bytearray()
    current = 0
    filled = 0

    def write(value: int, length: int) -> None:
        nonlocal current, filled
        for shift in range(length - 1, -1, -1):
            current = current << 1 | value >> shift & 1
            filled += 1
            if filled == 8:
                payload.append(current)
                current = filled = 0

    position = 0
    while position < total:
        count, code = choices[position]
        if code:
            write(code.bits, code.length)
        else:
            write(63, 6)
            write(count - 1, 3)
            write(pixels[position], 4)
        position += count
    if filled:
        payload.append(current << 8 - filled)
    return header.tiles.to_bytes(2, "big") + original[2 : header.payload_start] + payload


def compress_bytes(data: bytes, tool: str | None = None, *, accurate: bool = True) -> bytes:
    """Encode arbitrary Nemesis art with an explicitly installed compressor."""
    import os
    import shutil
    import subprocess
    import tempfile
    from pathlib import Path

    executable = tool or os.environ.get("NEMESIS_TOOL") or shutil.which("clownnemesis-tool")
    if not executable:
        raise FileNotFoundError("Set NEMESIS_TOOL to clownnemesis-tool, or provide its path")
    with tempfile.TemporaryDirectory(prefix="s1tools-nemesis-") as folder:
        source = Path(folder) / "input.bin"
        output = Path(folder) / "output.nem"
        source.write_bytes(data)
        subprocess.run(
            [executable, "-ca" if accurate else "-c", str(source), str(output)],
            check=True,
            capture_output=True,
        )
        result = output.read_bytes()
    if decode(result) != data:
        raise ValueError("Compressor output does not reproduce input bytes")
    return result
