# s2_improvements — notes for Claude Code

Sonic 2 disassembly mod (68000 asm, AS assembler), meant as a platform for future modifications.
The user writes in Russian; answer in Russian.

## Workflow
- Work on the current branch `codex/upstream-2026-10-03`. Commit locally, **never push**.
- Build: `build_tools/lua/lua.exe build.lua` (or `build.bat`, options pass through). Output `s2built.bin` + `s2.lst`.
  Every build includes the MD Debugger and a ConvSym symbol table and is padded with $FF to 2 MiB
  (`--no-symbols`, `debug` options; see `_debug/md-debugger/README.md`). `ErrorHandler.asm` must stay the
  last thing in the ROM. The build prints the Z80 driver headroom before the music buffer.
- Working copies of `.asm` files are LF (`git checkout` may turn them into CRLF because of `.gitattributes`;
  run `sed -i 's/\r$//'` before scripted edits). Git's CRLF warning on commit is expected.
- `jump distance too big` after adding code: replace that branch with `jsr`/`jmp (Label).l` (many branches are
  within a few hundred bytes of the 32 KB limit).
- Gameplay additions have `Feature*` switches near the top of `s2.asm` (README "Feature options"). New features
  get one too: default 1, 0 restores the original code path, and the default build must stay identical.
- Comparing builds: code/data must match up to `EndOfRom` (from `s2.lst`); the debugger symbol table and header
  checksum after it change whenever labels are added.
- Regression tests (unicorn 2.1.4 lives in the Codex work folder below):
  ```
  PYTHONPATH="C:/Users/Daniel/Documents/Codex/2026-10-03/d-projects-oranguthang-s2-improvements/work/emulation-deps" python tests/test_stage1.py . --baseline "C:/Users/Daniel/Documents/Codex/2026-10-03/d-projects-oranguthang-s2-improvements/work/stage1-baseline" --report stage1.json
  ```
  Every boolean in the report must be true.
- Real emulator: `python tests/check_demo_cycle.py` plays the title demos in Genesis Plus GX via the
  libretro harness `work/retro.py` from the Codex folder. Healthy cycle (6 demos):
  EHZ 2P, CPZ1, ARZ, CNZ1 (originals), CPZ1 assist (~53 carry frames), CNZ1 assist (flight, no carry); no deaths.
  Frame counts may differ by 1-2 between builds (lag frames).
- Harness tips: RetroPad ids B=0 (Genesis B), Y=1 (Genesis A), START=3, UP=4, DOWN=5, LEFT=6, RIGHT=7, A=8 (Genesis C).
  Level Select needs `debugTesting = 1` and Genesis A held while pressing Start on the title (game mode $28).
  Writing Game_Mode on the title does not start a level; press Start repeatedly. Audio can be captured by
  replacing the harness' audio_sample_batch callback; queue sounds from the Options menu (mode $24) after
  sending `$FD` (stop), since the title screen starts its own music.

## History
- Earlier work was done in Codex (ChatGPT), thread "S2 Improvements", id `01a10201-401e-7263-a785-9018dba21011`,
  log `C:\Users\Daniel\.codex\sessions\2026\10\03\rollout-2026-10-03T16-43-18-01a10201-401e-7263-a785-9018dba21011.jsonl`.
  Codex working files (old guide audit, emulator harness):
  `C:\Users\Daniel\Documents\Codex\2026-10-03\d-projects-oranguthang-s2-improvements\{outputs,work}`.
- Offline Markdown mirror of all Sonic Retro SCHG How-to guides (every game): `D:\Projects\oranguthang\sonicretro_guides`
  (S2: `sonic-2/INDEX.md`; refresh with `python fetch_guides.py` there).
- Commits a835209..b2e1a99 were made by gpt-6.1-sol; e09dde6 (Tails flight/carry, shield DPLC, spring twirl,
  music per act, demos) was committed by gpt-6-luna on top of sol's uncommitted flight code.
- 2026-10-05 (Claude Code): reviewed sol/Luna commits (fixes 760d345, 63bc5c3, 1ef01b3); re-audited all 71 S2
  guides against the code (49 done, 13 not done, 7 reference, 1 flag, 1 prototype-only), then platform stages:
  - Stage 1: removed `preserveLegacyROM` (all upstream fixes on), Tails air cap, `debugTesting` flag and
    `dbglistcommon`, dropped `ArtNem_Shield`, `useFullWaterTables = 1`, MD Debugger like s1_improvements.
  - Stage 2: zone tables enforce `no_of_zones` (README "Adding a zone", verified with a cloned zone $11),
    data-driven Level Select pages, music IDs from $01 with per-song bank pointers (OptimiseDriver on),
    `PlayerMode_*` constants, MEMORY.md.

## Known risks / open items
- 2026-10-14: swimming, tired swimming, drowning while swimming, surfacing, carrying Sonic out of the water
  and Tails' respawn while Sonic is underwater were checked in Genesis Plus GX (ARZ1, CPZ2) by scripted
  inputs and RAM teleports, not by a full play-through. Cosmetic: when Tails lands while carrying, Sonic falls
  in the hanging pose until he lands.
- Tails AI respawns even while Sonic is airborne or underwater (e09dde6 removed those checks on purpose for swimming).
- Flight and the assist are disabled in the four original title demos (scripts predate flight); the EHZ 2P
  demo still drifts from frame 742 because Tails no longer has an air speed cap.
- Tails' air speed cap removal changed AI physics slightly (ARZ demo 1712->1710 frames).
- Sound IDs: SFX start at $20 now. Never compute IDs from a hard-coded $A0/$80 base (Tails flight sounds broke
  that way once); use `SndID__First`/`MusID__First` or the `MusID_`/`SndID_` constants.
- See MEMORY.md before using SST bytes or RAM ($20/$21/$23 are per-character on players).
- Player VRAM: Tails body frames may exceed 16 tiles only when the separate tails object (Obj05) is blank.

## Possible next steps
Play-test flight/carry/swimming; stage 3 (S3K rings/object managers with 2P support, only if needed);
Knuckles with VS support; HTZ in VS; Hidden Palace (slot $08 exists).
