# MD Debugger error screen

Every build (`build.bat`, `build.lua`) produces `s2built.bin` with the blue MD Debugger 2.6 exception screen and a ConvSym DEB2 symbol table. `build.lua debug` produces the same configuration under the separate name `s2built.debug.bin`. The ROM is padded with `$FF` after appending symbols, to a power-of-two cartridge size starting at exactly 1 MiB (the current ROM is 2 MiB). The checksum and ROM-end header are fixed after padding. No intentional crash is present in gameplay code.

The exception screen shows the error, the faulting address and PC with their symbols, D0-D7, A0-A6, SP, SR, USP and the stack. A opens address-register symbols, B opens the backtrace, and Start returns to the exception screen. Unused vectors, unexpected interrupts and TRAPs go through `ErrorTrap`, which reports them on the same screen. This diagnostic screen is independent of the in-game Debug mode. Upstream documentation: https://github.com/vladikcomper/md-modules/tree/master/modules/errorhandler

The debugger also provides `RaiseError`, `assert`, `Console` and `KDebug` macros (see `Debugger.asm` and the upstream documentation) for diagnostics in new code.

## Layout rule

`ErrorHandler.asm` is included at the very end of `s2.asm`, and ConvSym appends the symbol table directly after it; the debugger looks for the table right behind its own blob. Never put data after the `ErrorHandler.asm` include: add new code and resources above it. `padToPowerOfTwo` must stay 0 because `build.lua` pads after the symbol table; the assembler stops with an error otherwise.

## Building without the symbol table

Symbols are enabled by default. To omit them explicitly:

```sh
build_tools/lua/lua.exe build.lua --no-symbols
# Alternate output name:
build_tools/lua/lua.exe build.lua debug --no-symbols
```

`build.bat` passes the same options through. Both commands keep the blue error screen and its numeric PC/register/stack display; function names and symbolic backtrace labels are unavailable, and ConvSym is not used. No DEB2 table is appended: the debugger detects the missing signature and falls back to numeric addresses. Padding must always follow any symbol table, never separate it from the debugger blob.

Setting `MDDebugger = 0` (for example `-D MDDebugger=0` in `build.lua`) restores the original freeze-on-crash behaviour without the debugger code.

## Tools and platforms

Builds with symbols need ConvSym 2.12.1 in addition to the existing assembler and p2bin. Official Windows x86_64 and Linux x86_64 executables are bundled in `build_tools/Windows-x86/` and `build_tools/Linux-x86_64/`; other platforms can build ConvSym from https://github.com/vladikcomper/md-modules/tree/master/utils/convsym and either place it in the appropriate `build_tools/<platform>/` directory or set the `CONVSYM` environment variable to its path. Linux users may need `chmod +x build_tools/Linux-x86_64/convsym` after extracting a ZIP.

Official release: https://github.com/vladikcomper/md-modules/releases/tag/v.2.6-mddebugger

Assembly bundles and ConvSym binaries are redistributed under the included MIT license, copyright Vladikcomper. The ErrorHandler blob is unchanged from the `as` release bundle. Configuration is in `_debug/md-debugger/Debugger.asm`; SR/USP display is enabled for this project.
