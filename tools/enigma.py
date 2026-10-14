"""Enigma decompression and compression (from s1_improvements' s1tools)."""

from __future__ import annotations


class _Bits:
    def __init__(self, blob: bytes, offset: int):
        self.blob = blob
        self.bit = offset * 8

    def read(self, count: int) -> int:
        value = 0
        for _ in range(count):
            if self.bit >= len(self.blob) * 8:
                raise ValueError("Truncated Enigma stream")
            value = value << 1 | self.blob[self.bit // 8] >> 7 - self.bit % 8 & 1
            self.bit += 1
        return value

    def peek(self, count: int) -> int:
        saved = self.bit
        try:
            return self.read(count)
        finally:
            self.bit = saved


def decode(blob: bytes, base: int = 0, legacy_literal_as_incremental: bool = False) -> list[int]:
    """Return the decoded words exactly as EniDec writes them with d0 = base.

    legacy_literal_as_incremental reproduces the old gallery decoder bug and is
    only meant for comparing against results made with it.
    """
    if len(blob) < 6:
        raise ValueError("Enigma file is too short")
    inline_bits = blob[0]
    flags = blob[1] & 31
    incremental = int.from_bytes(blob[2:4], "big") + base & 65535
    literal = int.from_bytes(blob[4:6], "big") + base & 65535
    bits = _Bits(blob, 6)

    def inline() -> int:
        value = base
        if flags & 16 and bits.read(1):
            value |= 32768
        if flags & 8 and bits.read(1):
            value += 16384
        if flags & 4 and bits.read(1):
            value += 8192
        if flags & 2 and bits.read(1):
            value |= 4096
        if flags & 1 and bits.read(1):
            value |= 2048
        return value + bits.read(inline_bits) & 65535

    words: list[int] = []
    while True:
        if bits.peek(1) == 0:
            entry = bits.read(6)
            kind = 0 if entry & 16 == 0 or legacy_literal_as_incremental else 1
            count = (entry & 15) + 1
        else:
            entry = bits.read(7)
            kind = entry >> 4
            count = (entry & 15) + 1
        if kind == 0:
            for _ in range(count):
                words.append(incremental)
                incremental = incremental + 1 & 65535
        elif kind == 1:
            words.extend([literal] * count)
        elif kind == 4:
            words.extend([inline()] * count)
        elif kind == 5:
            value = inline()
            for _ in range(count):
                words.append(value)
                value = value + 1 & 65535
        elif kind == 6:
            value = inline()
            for _ in range(count):
                words.append(value)
                value = value - 1 & 65535
        else:
            if count == 16:
                break
            words.extend(inline() for _ in range(count))
    return words


def decode_bytes(blob: bytes, base: int = 0, legacy_literal_as_incremental: bool = False) -> bytes:
    """Decoded words packed big-endian, like the RAM buffer EniDec fills.

    Drop-in replacement for the former level_layout_gallery.decode_enigma().
    """
    words = decode(blob, base, legacy_literal_as_incremental)
    return b"".join(word.to_bytes(2, "big") for word in words)


def entry_histogram(blob: bytes) -> dict[str, int]:
    """Count format list entries by type (diagnostics)."""
    names = {
        0: "incremental",
        1: "literal",
        4: "inline repeat",
        5: "inline +1",
        6: "inline -1",
        7: "inline list",
    }
    counts = {name: 0 for name in names.values()}
    inline_bits = blob[0]
    flags = blob[1] & 31
    extra = bin(flags).count("1")
    bits = _Bits(blob, 6)
    while True:
        if bits.peek(1) == 0:
            entry = bits.read(6)
            kind = 0 if entry & 16 == 0 else 1
        else:
            entry = bits.read(7)
            kind = entry >> 4
        count = (entry & 15) + 1
        if kind == 7 and count == 16:
            break
        counts[names[kind]] += 1
        if kind in (4, 5, 6):
            bits.read(extra + inline_bits)
        elif kind == 7:
            bits.read((extra + inline_bits) * count)
    return counts


def encode(words: list[int]) -> bytes:
    """Encode words as Enigma without flag bits (16-bit inline values).

    Runs of zero use the literal value, other runs repeat one inline value,
    and everything else is written as lists of up to 15 inline values. The
    output is valid for EniDec but not as small as the original tools make.
    """
    # 16 inline bits, no flag bits, incremental and literal values both 0.
    out = bytearray([16, 0, 0, 0, 0, 0])
    stream: list[str] = []

    def put(value: int, width: int) -> None:
        stream.append(format(value, f"0{width}b"))

    index = 0
    pending: list[int] = []

    def flush() -> None:
        while pending:
            chunk = pending[:15]
            del pending[:15]
            put(0b111, 3)
            put(len(chunk) - 1, 4)
            for value in chunk:
                put(value, 16)

    while index < len(words):
        value = words[index]
        run = 1
        while index + run < len(words) and words[index + run] == value and run < 16:
            run += 1
        if value == 0:
            flush()
            put(0b01, 2)
            put(run - 1, 4)
            index += run
        elif run >= 2:
            flush()
            put(0b100, 3)
            put(run - 1, 4)
            put(value, 16)
            index += run
        else:
            pending.append(value)
            index += 1
    flush()
    put(0b1111111, 7)  # inline list of 16 entries ends the stream
    bits = "".join(stream)
    bits += "0" * (-len(bits) % 16)
    out.extend(int(bits[i : i + 8], 2) for i in range(0, len(bits), 8))
    return bytes(out)
