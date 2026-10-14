# s2_improvements

`s2_improvements` is a Sonic the Hedgehog 2 disassembly-based project focused on gameplay, engine, and quality-of-life improvements implemented from Sonic Retro tutorials.

This repository is built on top of the Sonic 2 community disassembly and gradually ports fixes and features from the Sonic Retro hacking guides into one project.

To build this project, use `build.bat` on Windows, or `build.lua` otherwise. The built ROM will be called `s2built.bin`. The Lua script requires Lua 5.3 or later.

Every build includes the MD Debugger exception screen with a ConvSym symbol table, so crashes show the faulting label, registers, stack and backtrace instead of freezing. The ROM is padded with `$FF` to a power-of-two size (currently 2 MiB) after the symbols. Use `build.lua --no-symbols` to omit symbol names, or `build.lua debug` for the alternate `s2built.debug.bin` name. See [the debugger guide](_debug/md-debugger/README.md) for controls, the end-of-ROM layout rule and tool requirements, and [CREDITS.md](CREDITS.md) for third-party components.

See also:
- Sonic Retro Disassemblies: https://info.sonicretro.org/Disassemblies
- Sonic Retro How-To guides: https://info.sonicretro.org/SCHG_How-to:Guide

## Upstream migration and ROM compatibility

This branch ports the improvements from `master` at `bfadfbd` onto Sonic Retro
upstream `380f37a`. The roll-jump collision-height fix from `a2f70eb` is already
provided by upstream; the other 37 commits have been replayed with conflicts
resolved.

All upstream fixes are enabled together with `fixBugs = 1`. The temporary
`preserveLegacyROM` switch, which kept the ROM byte-identical to the old
`master` during the migration, has been removed: it disabled real fixes (HTZ
boss crash, running through walls, clipping onto floors from below, HTZ rising
floor, OOZ launchers, ending music fade and others). The migration itself was
verified before the switch was removed: `master` at `bfadfbd` and the ported
branch built the same 1,081,322-byte ROM, MD5 `ca1f52e9cb999f5fa92d665d3eb508a4`.

To compare two builds byte by byte, use the bundled Lua:

```bat
build_tools\lua\lua.exe compare_roms.lua baseline.bin s2built.bin
```

The comparison checks every byte and the file lengths. It exits successfully
only when both ROMs are identical, and otherwise prints the differing-byte
count and first offset.

## Current improvement plan

Work continues on the current branch with separate local commits and no pushes.

| Improvement | Progress | Validation |
| --- | --- | --- |
| Separate Sega screen graphics from Sonic | Implemented | Compare all four copied and enlarged frames with the baseline; mutate player art to check independence |
| Restore burnt death animation | Implemented | Fire hazards, other deaths, Sonic and Tails |
| Support six-button controllers | Implemented | Both ports, three-button fallback, held/pressed transitions |
| Configure VS countdown | Implemented | All three start triggers, HUD, music and expiry |
| Improve character Debug mode | Implemented | Tails Alone, movement reset, cameras, water, HUD and Level Select |
| Preserve level state after Special Stage | Implemented | Rings, object consumption and shields for both players; ordinary deaths and new levels |

Hidden Palace from the official 2013 remake is a later project, outside this batch.

## Implemented Sonic Retro tutorials

- [Fix bugs relating to Super Sonic](https://info.sonicretro.org/SCHG_How-to:Fix_bugs_relating_to_Super_Sonic)
- [Use correct height when roll jumping](https://info.sonicretro.org/SCHG_How-to:Use_correct_height_when_roll_jumping)
- [Fix jump height bug when exiting water](https://info.sonicretro.org/SCHG_How-to:Fix_jump_height_bug_when_exiting_water)
- [Fix screen boundary spindash bug](https://info.sonicretro.org/SCHG_How-to:Fix_screen_boundary_spindash_bug)
- [Correct drowning bugs](https://info.sonicretro.org/SCHG_How-to:Correct_Drowning_Bugs_in_Sonic_2)
- [Fix camera y position for Tails](https://info.sonicretro.org/SCHG_How-to:Fix_camera_y_position_for_Tails)
- [Fix Tails subanimation error](https://info.sonicretro.org/SCHG_How-to:Fix_Tails_subanimation_error)
- [Fix accidental deletion of scattered rings](https://info.sonicretro.org/SCHG_How-to:Fix_Accidental_Deletion_of_Scattered_Rings)
- [Fix ring timers](https://info.sonicretro.org/SCHG_How-to:Fix_Ring_Timers)
- [Fix monitor collision bug](https://info.sonicretro.org/SCHG_How-to:Fix_monitor_collision_bug)
- [Fix bug in ARZ boss arrow's platform behavior](https://info.sonicretro.org/SCHG_How-to:Fix_bug_in_ARZ_Boss_arrow%27s_platform_behavior)
- [Fix Hill Top's background scrolling mountains](https://info.sonicretro.org/SCHG_How-to:Fix_Hill_Top%27s_background_scrolling_mountains)
- [Fix the OOZ launcher speed up glitch](https://info.sonicretro.org/SCHG_How-to:Fix_the_OOZ_launcher_speed_up_glitch)
- [Fix DEZ Eggrobo boss collision glitch](https://info.sonicretro.org/SCHG_How-to:Fix_DEZ_Eggrobo_boss_collision_glitch)
- [Fix Speed Bugs in Sonic 2](https://info.sonicretro.org/SCHG_How-to:Fix_Speed_Bugs_in_Sonic_2)
- [Remove the Air Speed Cap](https://info.sonicretro.org/SCHG_How-to:Remove_the_Air_Speed_Cap)
- [Remove the Roll-Jump Lock](https://info.sonicretro.org/SCHG_How-to:Remove_the_Roll-Jump_Lock_in_Sonic_2)
- [Disable floor collision while dying](https://info.sonicretro.org/SCHG_How-to:Disable_floor_collision_while_dying)
- [Modify Transformation Behavior](https://info.sonicretro.org/SCHG_How-to:Modify_Transformation_Behavior_in_Sonic_2)
- [Collide with water after being hurt](https://info.sonicretro.org/SCHG_How-to:Collide_with_water_after_being_hurt)
- [Retain Rings when returning at a Star Post](https://info.sonicretro.org/SCHG_How-to:Retain_Rings_when_returning_at_a_Star_Post)
- [Improve the fade in/fade out progression routines](https://info.sonicretro.org/SCHG_How-to:Improve_the_fade_in/fade_out_progression_routines_in_Sonic_2)
- [Fix Scattered Rings Underwater Physics](https://info.sonicretro.org/SCHG_How-to:Fix_Scattered_Rings_Underwater_Physics)
- [Insert Labyrinth Zone water ripple effect](https://info.sonicretro.org/SCHG_How-to:Insert_Labyrinth_Zone_water_ripple_effect_in_Sonic_2)
- [Restore lost CPZ boss feature](https://info.sonicretro.org/SCHG_How-to:Restore_lost_CPZ_boss_feature)
- [Prevent SCZ Tornado spin dash death](https://info.sonicretro.org/SCHG_How-to:Prevent_SCZ_Tornado_spin_dash_death)
- [Change Special Stage characters to use normal DPLCs](https://info.sonicretro.org/SCHG_How-to:Change_the_Special_Stage_characters_to_use_normal_DPLCs)
- [Add Extra Item Options for 2 Player VS Mode](https://info.sonicretro.org/SCHG_How-to:Add_Extra_Item_Options_for_2_Player_VS_Mode)
- [Add Flamewing's UltraDMAQueue to Sonic 2](https://info.sonicretro.org/SCHG_How-to:Add_Flamewing%27s_UltraDMAQueue_to_Sonic_2)
- [Improve ObjectMove subroutines](https://info.sonicretro.org/SCHG_How-to:Improve_ObjectMove_subroutines)
- [Speed Up Ring Loss Process (With Underwater)](https://info.sonicretro.org/SCHG_How-to:Speed_Up_Ring_Loss_Process_(With_Underwater))
- [Add the Air Roll/Flying Spin Attack](https://info.sonicretro.org/SCHG_How-to:Add_the_Air_Roll/Flying_Spin_Attack)
- [Skip Score Tallies](https://info.sonicretro.org/SCHG_How-to:Skip_Score_Tallies)
- [Add Extended Camera to Sonic 1](https://info.sonicretro.org/SCHG_How-to:Add_Extended_Camera_to_Sonic_1)
- [Create a Homing Attack from scratch](https://info.sonicretro.org/SCHG_How-to:Create_a_Homing_Attack_from_scratch)

- [Decouple Sega screen from Sonic sprite labels](https://info.sonicretro.org/SCHG_How-to:Decoupling_Sega_Screen_from_Sonic_Sprite_Labels_in_Sonic_2)

- [Restore burnt death animation](https://info.sonicretro.org/SCHG_How-to:Restore_the_Burnt_Death_Animation)

- [Add six-button support](https://info.sonicretro.org/SCHG_How-to:Add_6_button_support)

Extended input for both ports is available as `Ctrl_1_Held_6B` /
`Ctrl_1_Press_6B` and `Ctrl_2_Held_6B` / `Ctrl_2_Press_6B`.
Bits 0..3 represent Z, Y, X and Mode; bit 7 of Held indicates a detected
six-button pad. Existing three-button controls remain available. Extended
buttons are exposed for future ability bindings; they do not grant rings,
lives or other tutorial test cheats.

- [Toggle the VS countdown](https://info.sonicretro.org/SCHG_How-to:Toggle_the_2_Player_VS_Countdown)

In Options, select **VS MODE ITEMS** and press **A** on either controller to
cycle the finish countdown between **60 seconds**, **90 seconds** and **off**.
The setting covers signpost loading and either player's finish, and hides the
countdown digits when inactive. The normal countdown music and expiry remain.

- [Improve Debug mode](https://info.sonicretro.org/SCHG_How-to:Improve_Debug_Mode)

Debug now works for Tails Alone, including entry while hurt or dying. Placement
resets camera offsets and air, hides Tails' separate tail sprite, and exiting
restores the correct character, collision size, movement and normal HUD.
All existing debug lists include the individual monitor types. In Level Select,
**C** cycles Sonic and Tails / Sonic Alone / Tails Alone except on Sound Test;
the current choice is shown below the level list. With the slow-motion cheat
enabled, **A** while paused returns to Level Select with water/checkpoint state
reset and standard HUD graphics reloaded on starting a level.

For testing builds, set `debugTesting = 1` at the top of `s2.asm`: Level Select,
slow motion and Debug mode are then unlocked on boot without entering cheats.
Objects that every zone can place (ring and all monitor types, whose art comes
from the standard pattern load requests) live in the `dbglistcommon` macro used
by every debug list; add new universal objects there.

- [Restore level state after a Special Stage](https://info.sonicretro.org/SCHG_How-to:Restore_level_state_after_a_Special_Stage)

Entering a Special Stage through a star post now preserves collected level rings,
destroyed enemies/monitors, CNZ saucer group counters and each player's ring count,
extra-life thresholds and shield. Active remembered objects reload normally;
explosions do not revive dead enemies. In-flight ring pickups finish on return.
Temporary invincibility and speed shoes expire, while earned lives/score remain.
The snapshot is consumed once; ordinary deaths keep the existing checkpoint ring
behavior, and new acts, demos, VS and Level Select do not reuse Special Stage state.

- [Add MD Debugger and Error Handler](https://info.sonicretro.org/SCHG_How-to:Add_MD_Debugger_and_Error_Handler_to_Sonic_1)
  (Sonic 2 installation per the [official guide](https://github.com/vladikcomper/md-modules/blob/master/modules/errorhandler/docs/installation/Sonic_2_Github.md);
  see [the debugger guide](_debug/md-debugger/README.md))

## Feature options

The `Feature*` switches near the top of `s2.asm` turn this project's gameplay
additions on (1, the default) or off (0). Off restores the original Sonic 2
behaviour for that feature only. The code stays assembled but is never entered,
so a feature can be switched off without moving data or touching other
features. The default build is unchanged by these switches.

| Option | When 0 |
|---|---|
| `FeatureAirRoll` | Pressing A/B/C in the air while not curled does nothing (Sonic and Tails). |
| `FeatureHomingAttack` | No Homing Attack or Jump Dash. |
| `FeatureExtendedCamera` | The camera keeps the original fixed focus. |
| `FeatureMomentum` | Air control caps speed at the running limit again (Sonic and Tails). |
| `FeatureRollJumpSteering` | A jump from a roll locks midair steering again. The Homing Attack flag then moves from `status` bit 4 to `status_secondary` bit 4. |
| `FeatureSuperToggle` | Super Sonic starts at the peak of a jump (7 emeralds, 50 rings), and there is no button combo to turn back. |
| `FeatureInstantTally` | The act bonus always counts down, and the act jingle starts as soon as the tally begins. |
| `FeatureLamppostRings` | Restarting from a star post starts with no rings. |
| `FeatureSpecialStageState` | Coming back from a Special Stage restarts the level from the star post (no rings, no shield, objects respawn). |
| `FeatureSpringPoses` | Sonic uses the original single spring pose. |
| `FeatureBurntDeath` | Fire hazards and lasers use the normal death animation. |
| `FeatureTailsFlight` | Tails cannot fly or swim, Up + jump does not call the Tails AI, the AI respawns only while Sonic is on the ground and out of water, and the title screen plays only the four original demos. |
| `FeatureActMusic` | Act 2 of EHZ, MCZ and CNZ plays the act 1 track. |
| `FeatureExtraLives` | Rings give lives only at 100 and 200, as in the original game. |
| `FeatureInvincibilityFlash` | The invincibility stars stay steady until they vanish. |
| `FeatureFastSoundTest` | B+A no longer steps the sound tests back by $10 (A still steps ahead by $10). |
| `FeatureSpecialStageSelect` | SPECIAL STAGE in the Level Select starts the next stage in order, without a number; replaying a stage can count its emerald twice. |
| `FeatureCentiseconds` | The 1P clock shows minutes and seconds only. |
| `FeatureLightDash` | A in the air never starts a Light Dash; it does the normal air move. |
| `FeaturePeelOut` | Up + A/B/C while standing jumps, as in the original game. |
| `FeatureVictoryPoses` | After the signpost the player runs off to the right before the results, as in the original game. |
| `FeatureSuperTails` | Tails cannot turn Super. |
| `FeatureKnuckles` | The player select has no Knuckles entries. |
| `FeatureS3KDrums` | With Flamedriver, Sonic 2 songs play Sonic 2's own kick, snare and timpani samples. |
| `FeatureImprovedMusic` | With Flamedriver, seven songs keep their original note data (see Sound driver). |

Two optional alternatives are off by default; 1 enables them:

| Option | When 1 |
|---|---|
| `FeatureInfiniteLives` | 1P games hide the lives counter and never end: dying (Time Over too) restarts the act without using a life, rings, score and 1-ups give no lives, and 1-up monitors give 10 rings. 2P VS games keep their lives. |
| `FeatureCDDrowning` | As in Sonic CD, the music keeps playing below 12 seconds of air and the water warning sounds every second; the countdown numbers still appear. The invincibility music is no longer held back while air is low. |

With `FeatureCentiseconds` the clock reads `0:00:00` (after Selbi's
[Add Centiseconds HUD](https://info.sonicretro.org/SCHG_How-to:Add_Centiseconds_HUD)).
The second colon reuses the HUD colon tile and the two digits use the four
free tiles after the horizontal scroll table (`$7FC-$7FF`); BuildHUD queues
them by DMA from a lookup table only when the hundredths change. The ARZ title
demo runs right at the edge of the frame budget, so even this small cost makes
it about 20 lag frames longer (1712 -> 1734 frames; the per-frame checks of the later features add a few more, 1742); a 300-cycle empty loop
in the same place costs 14. The optimizations below bring it back to 1693. With
`FeatureSpecialStageSelect`, Left/Right on SPECIAL STAGE choose the stage shown
as 1-7 after the name, and an emerald that was already earned is not counted again.

`FeatureSoundDriver` picks the sound driver: 2 (the default) is Flamedriver,
0 is Sonic 2's own Z80 driver; see Sound driver below.

With every switch at 0 the four original title demos play through without a
death. Bug fixes from `fixBugs`, the Sonic Retro fix tutorials and the menu
options (VS countdown, VS items) have no switch.

## Cheats and settings

**Unlocking.** Either the original sound test code 19, 65, 9, 17 (in Options)
or the Sonic 1 code Up, Down, Down, Down, Left, Right on the title unlocks the
Level Select (hold **A** and press Start on the title) with its CHEATS item.
The other original codes still work (debug 1, 9, 9, 2, 1, 1, 2, 4 and the
emeralds 4, 1, 2, 6 in the Level Select sound test, continues 1, 1, 2, 4).
With the unlock, **A** while paused returns to the Level Select.

**CHEATS** is the item below the player option in the Level Select. Up/Down
select, Left/Right/A/B/C change, Start returns to the level list.

| Setting | Values | Default | Effect |
|---|---|---|---|
| ALL EMERALDS | OFF / ON | OFF | Counts as seven emeralds for Super Sonic, the Super ending and the star post stars. The real emeralds are kept. Not in 2P games or demos. |
| DEBUG | OFF / ON | OFF | Debug mode in every level (B enters object placement) without holding A. Same flag as the debug sound test code. |
| SUPER RINGS | 0 / 10 / 50 | 50 | Rings needed to turn Super. 0 turns RING DRAIN off. |
| RING DRAIN | OFF / ON | ON | OFF keeps Super Sonic until the act ends. Turning it on at 0 rings sets SUPER RINGS to 10. |
| GOD MODE | OFF / ON | OFF | Nothing hurts or kills the players, the air never runs out, the clock stops at 9:59 and a pit bounces the player back up. Not in 2P VS games or demos. |

As in s1_improvements, B does not enter object placement while it is part of
an airborne A+B or B+C Super combo.

**Debug coordinates.** While debug mode is available in a 1P game, the upper
right corner shows the camera X/Y (top row) and the player X/Y (second row) in
hex, then SPR and the number of sprites drawn; SCORE and TIME keep their
meaning. The overlay borrows the sidekick's shield tiles and hides while the
sidekick has a shield.

**SRAM.** The header declares battery-backed odd-byte SRAM at
`$200001-$20FFFF`. `code/Settings.asm` keeps one record there: logical byte N
is at `$200001+2*N`; bytes 0-3 `S2DV`, 4 the format version (1), 5 the payload
length (9), then the Level Select unlock, DEBUG, ALL EMERALDS, SUPER RINGS,
RING DRAIN, GOD MODE, the player option, the VS items and the VS countdown,
then a big-endian additive checksum of everything before it. A cold boot loads
it (defaults for a missing or damaged record); leaving Options or the Level
Select, any change on the CHEATS page and a successful unlock code save it.
A write invalidates the signature first and commits it last. To add a setting,
append its RAM byte to `Settings_Fields`, clamp it in `Settings_Normalize` and
raise `settings_sram_version`. Emerald, lives and level progress are not saved.

## Memory

[MEMORY.md](MEMORY.md) lists the object fields and RAM the mod's features use
and the RAM that is still free.

## Adding a zone

Zone IDs are declared with `zoneID` in `s2.constants.asm`; `no_of_zones` follows
the list. Every per-zone table is a `zoneOrderedTable`/`zoneOrderedOffsetTable`
(or `LevelArtPointers`), and the build stops if a table does not have exactly
`no_of_zones` entries. To add a zone:

1. Declare it after the last ID, e.g. `new_zone zoneID $11`, and its act
   constants (`new_zone_act_1 = (new_zone<<8)|$00`).
2. Build. The errors list every table that needs an entry (26 tables:
   level art/blocks/palette, layouts, objects, rings, collision, start
   positions, level size, camera, scrolling, level events, animated art and
   blocks, palette cycles, water height and routine, music for 1P and VS,
   animals, title card name and letters, debug list, demo script and level
   order for 1P and VS). Add the entries in zone order.
3. Draw the zone name in `MapUnc_TitleCards` and list its letters in
   `TitleCardLetters`. The frames after the zone names move automatically;
   use the `TitleCardFrame_*` constants instead of frame numbers.
4. Add the zone to a Level Select page if it should be selectable (see below).

This was verified with a temporary zone `$11` cloned from Emerald Hill: title
card, art, objects, rings, Tails and gameplay matched EHZ. Limits: Level Select
encodes special entries with bits 14 and 15 of the zone/act word, so zone IDs
must stay below `$40`; zone offset tables use word offsets, so a table and its
data must stay within 32 KB (the assembler reports an overflow). SCZ, WFZ and
DEZ hand over to the next zone from their objects (`ObjB2`, the WFZ ending
events and the Death Egg robot), not through `LevelOrder`.

## Level Select pages

The Level Select is driven by `LevelSelect_Pages`, based on
[Extend the Level Select](https://info.sonicretro.org/SCHG_How-to:Extend_the_Level_Select_in_Sonic_2).
The game ships with one page; the selected page and item are remembered while
the console is on. To add a page:

1. Draw its 40x28 screen mappings (Enigma) from `mappings/misc/Level Select.bin`,
   keeping the zone icon, sound test number and player option areas, and
   include them like `MapEng_LevSel`.
2. Write `Name_Order`, `Name_SwitchTable`, `Name_IconTable` and
   `Name_MarkTable` with one entry per item, each followed by a `_End` label,
   then `levselpagecheck Name` to verify their sizes.
3. Add `levselpage Name, mappings` to `LevelSelect_Pages`.

In order tables, `LevSelEntry_NextPage` and `LevSelEntry_PrevPage` switch pages
(with wrap-around) when Start is pressed, `LevSelEntry_SpecialStage` starts the
Special Stage, `LevSelEntry_Cheats` opens the CHEATS page and
`LevSelEntry_SoundTest` must be the last item of every page.

The optional third `levselpage` argument lists item names written into the
decompressed mappings before they are shown (`dc.w planeLoc(40,column,line)`,
`dc.l text`, `dc.w length-1`, ending with `dc.w -1`). The CHEATS item is added
to the stock page this way, so items can be added without new Enigma mappings.
Two pages were verified with a temporary copy of the stock page: NEXT and PREV
redraw instantly and items on either page start their own zone.

## Player modes

`Player_mode` (and `Player_option` in the menus) use the `PlayerMode_*`
constants from `s2.constants.asm` instead of 0/1/2, following the preparation
part of [Add Extra Characters](https://info.sonicretro.org/SCHG_How-to:Add_Extra_Characters_To_Sonic_2).
`PlayerMode_Count` drives the Options and Level Select choices, and the
assembler checks that the Options and Level Select name tables have one entry
per mode. The order matters: some checks treat modes above
`PlayerMode_SonicAlone` as Tails-led games and `tst.w (Player_mode)` tests for
Sonic and Tails. When adding a character, search for `PlayerMode_` and
`tst.w (Player_mode)`; the Special Stage HUD name frames (`andi.w #3`) also
need a frame per mode.

## Music and sound IDs

Based on [Expand the music index to start at $00](https://info.sonicretro.org/SCHG_How-to:Expand_the_music_index_to_start_at_%2400_instead_of_%2480).
`$00` means "nothing queued", music starts at `$01` and sound effects follow
the last song (currently `$20`); command IDs (`$F8-$FF`) are unchanged. The
sound tests in Options and Level Select cover `$00-$FF`, and their numbers
are the sound IDs themselves, so test numbers and cheat codes are the same as
before. Every `zMasterPlaylist` entry stores its song's ROM bank, flags and
address, so songs can go in any bank and a bank can hold any number of them
(the old limit was two banks of at most `$20` songs each). To add a song:
include it in a bank (`startBank`/`finishBank`), add a `music_metadata` entry
before `zMusIDPtr__End` with a `MusID_` constant, and a tempo byte to
`zSpedUpTempoTable`; compressed songs are listed in
`sound/music/list of compressed songs.txt`. `OptimiseDriver` is enabled to keep
the Z80 code below the music buffer.

All 31 songs, 81 sound effects, the SEGA chant and the speed-shoes tempo were
compared with the previous build in Genesis Plus GX: same loudness and
envelopes, with songs starting at most one frame apart.

## Sound driver

With `FeatureSoundDriver = 2`, [Flamedriver](https://github.com/flamewing/flamedriver),
Flamewing's improved Sonic 3 & Knuckles Z80 driver, plays all music and sound
effects, as in s1_improvements. Its files are in `sound/flamedriver/`
(`UPSTREAM_COMMIT.txt` names the version; the changes are the ID prefixes in
`_smps2asm_inc.asm`, the quiet `DebugSoundbanks`, a disabled `shared` line, and
`Tables.asm`, which holds the sample, music and sound effect tables in Sonic 2
order). The Sonic 2 songs and effects stay the SMPS2ASM sources in
`sound/music` and `sound/sfx`, converted for the driver while assembling;
`sound/S3K Music Bank.asm` and `sound/S3K SFX Bank.asm` place them in 32 KiB
banks, and the build Kosinski-compresses the Z80 program into the space
reserved by `Size_of_Snd_driver_guess` (`SoundDriverLoad` decompresses it).
Song IDs come from `Gen_Music_Table` and keep the `MusID_` names and numbers
($01-$1F); sound effect IDs follow from `Gen_Sound_Table` (`SndID_` = $20 +
position), so the sound tests and the IDs above are unchanged. To add a song,
add it to `Gen_Music_Table` and to a bank in `sound/S3K Music Bank.asm`.

The game keeps its Sonic 2 interface: `PlayMusic`, `PlaySound` and the pause
code fill `Sound_Queue`, and `sndDriverInput` (V-Int, Z80 stopped) jumps to
`SoundS3K_Input` in `sound/S3K Driver.asm`, which passes one song or command
per frame and up to two sound effects to the driver. Speed shoes use the
Sonic 3 & Knuckles tempo step of 8, the driver resumes the song under a 1-up
by itself, Ring and RingLeft alternate as in Sonic 2 (they must stay next to
each other in `Gen_Sound_Table`), and repeated Spin Dash revs rise in pitch as
in Sonic 3 & Knuckles. The SEGA chant is Sonic 2's own sample, resampled by
`tools/flamedriver_sega.py` to the driver's rate of about 14.4 kHz
(`sound/flamedriver/Sega PCM.bin`; `--check` verifies it); the SEGA screen reads
the controller without stopping the Z80 so the chant does not stall, and Start
ends it through `StopSegaPCM`. Differences from Sonic 2's driver: a fade-out
takes about 4.5 seconds instead of 3, and a pause leaves a faint decaying
release tail.

`FeatureS3KDrums` maps the DAC notes Sonic 2 songs use for the kick, snare and
timpani to the Sonic 3 & Knuckles samples (timpani rates $0B, $0E, $15, $16 and
$14, as in s1_improvements); 0 plays Sonic 2's samples through the same driver.
`FeatureImprovedMusic` applies the note fixes from Flamedriver's
`s2/music-improved` set that the sources here lacked: in MCZ (both versions),
OOZ, ARZ, CNZ 2P, Special Stage and Credits, a bare duration after a rest
becomes an explicit `nRst` (`if ImprovedMusicData` blocks in the song sources).
The rest of that set (PSG volume commands, voice and pitch fixes) is already in
the sources under `FixMusicAndSFXDataBugs`.

With `FeatureSoundDriver = 0` the build compresses Sonic 2's Z80 driver and
songs as before and the ROM is identical (up to `EndOfRom`) to the build before
Flamedriver was added. With Flamedriver, all 31 songs, 81 sound effects, the
SEGA chant and its Start skip, pause, speed shoes, fade-out and the 1-up
jingle were checked by audio capture in Genesis Plus GX, with both drum
settings.

## Optimizations

These change speed only: the output and the game's behaviour stay the same,
so they have no `Feature*` switch.

- Kosinski and Enigma decompression use the faster decoders from
  s1_improvements (vladikcomper's Kosinski decoder with MarkeyJester's and
  Flamewing's improvements, and an Enigma decoder with ideas from Malachi's),
  after [Improving compression formats](https://info.sonicretro.org/SCHG_How-to:Improving_compression_formats).
  They live in `code/Decompression.asm`; `KosDec` and `EniDec` jump there.
  All 86 Kosinski and Enigma assets in the ROM decompress to the same bytes,
  with the same registers, as with the original routines, using about a
  third fewer instructions.
- `CalcAngle` is shorter, as in s1_improvements (after
  [Improving CalcAngle subroutines](https://info.sonicretro.org/SCHG_How-to:Improving_CalcAngle_subroutines)),
  and the airborne collision of Sonic and Tails picks its direction with
  `CalcAirQuadrant` (`code/Math.asm`) instead of a division: it reproduces
  `(CalcAngle-$20)&$C0`, including the table's rounding near the diagonals.
  Both were compared with the original routines on 60000 speed pairs (edge
  values, near-diagonal and random), with identical results, registers and
  flags. The ARZ title demo, which runs at the edge of the frame budget, takes
  5 frames less (1741 -> 1736).
- `DisplaySprite`, `DisplaySprite2` and `DisplaySprite3` insert into the
  display lists as in s1_improvements (after
  [Improve DisplaySprite subroutines](https://info.sonicretro.org/SCHG_How-to:Improve_DisplaySprite_subroutines)):
  the list address comes from a table and a full list is detected by the
  entry count overflowing into bit 7, which needs eight lists of $80 bytes
  (checked at assembly). None of the 473 call sites reads `d0`, `a1`/`a2` or
  the flags afterwards, so the different values left there do not matter.
  Compared with the original on 18000 random list states: identical lists and
  registers. ARZ demo: 1736 -> 1731 frames.
- `TouchResponse` scans the dynamic objects with an unrolled loop
  (`Touch_ScanObjects`, `code/Touch.asm`): each slot is one absolute
  `move.b` of its `collision_flags` and a short branch, 22 cycles instead of
  42 for a slot without collision, and the original check code is called for
  the others. Sonic 1's collision queue ([Optimizing Collision System in Sonic 1](https://info.sonicretro.org/SCHG_How-to:Optimizing_Collision_System_in_Sonic_1),
  used by s1_improvements) is not used here: Sonic 2 objects often give
  collision_flags to other objects (projectiles, boss parts, lost rings), which
  a queue built while objects run would see a frame late. The scan checks
  the same objects in the same order with the same registers (except the loop
  counter `d6` and the final `a1`, which nothing reads); compared with the
  original on 3000 random object layouts around the player, RAM and registers
  were identical. ARZ demo: 1731 -> 1693 frames, now shorter than before
  `FeatureCentiseconds` (1712); EHZ 2P: 1645 -> 1641.

## Branch range

Sonic 2 has many `bsr.w`/`bra.w` branches within a few hundred bytes of the
32 KB limit, so adding code can make the assembler report `jump distance too
big` for an unrelated branch. Replace it with `jsr (Label).l` or
`jmp (Label).l` (or the disassembly's `jsrto`/`jmpto` macros).

## Regression checks

`tests/test_stage1.py` executes assembled ROM routines with Unicorn 2.1.4 on
an M68000 CPU. Install it with `python -m pip install unicorn==2.1.4`, then run:

```text
python tests/test_stage1.py . --baseline BASELINE_DIRECTORY --report stage1-test-report.json
```

The baseline directory must contain `s2built.bin` and `s2.lst` from `d6b2f27`.
Checks cover all six features and the title-palette skip fix, including actual
Special Stage/level RAM clears and manager initialization. VDP rendering and
physical controller timing still need a play-through in an emulator or on hardware.

## Custom fixes

- Prevent Tails from losing rings in Special Stage during co-op

## Disclaimer

Any and all content presented in this repository is presented for informational and educational purposes only.
Commercial usage is expressly prohibited. Sonic Retro claims no ownership of any code in these repositories.
You assume any and all responsibility for using this content responsibly. Sonic Retro claims no responsibility or warranty.

## Ability, graphics and demo additions

| Change | Status | Notes |
| --- | --- | --- |
| Knuckles | In progress | KNUCKLES AND MILES (TAILS) and KNUCKLES ALONE in the Options and Level Select player select, ported from s2disasm's [Knuckles in Sonic 2](https://github.com/sonicretro/s2disasm/tree/knuckles-in-sonic-2) disassembly (KiS2). As there, Knuckles is Obj01 with his own art, mappings, DPLCs, animations and moves, so objects treat him as Sonic; `Main_character` (`CharID_Sonic`/`CharID_Knuckles`) says who is in the Sonic slot and `ApplyPlayerOption` turns a player select entry into `Player_mode` and `Main_character`, so Knuckles and Tails is a Sonic and Tails game for all sidekick logic. `tools/import_kis2.py` copies the art (already in Sonic 2's palette indices), mappings and DPLCs from a fixed KiS2 commit and builds Knuckles' palettes: Sonic 2's with colours 2-5 of the first line (Sonic's blue) taken from KiS2, so Tails keeps his colours; Hidden Palace, which KiS2 lacks, gets the same underwater tint as Sonic. The art is aligned to a 128 KiB bank so no DPLC transfer crosses a DMA boundary. From KiS2: the jump ($600, $300 under water, Super too), the simpler balancing and the faster pushing animation. Knuckles has no Homing Attack, Air Roll, Super Peel-Out or blinking/lying down. Gliding, sliding, wall climbing and climbing onto ledges are KiS2's (`code/KnucklesGlide.asm`, with KiS2's own glide collision and wall checks): press A/B/C in a jump once he no longer rises fast (in Knuckles and Tails, Up + jump still calls Tails), hold to glide and steer with Left/Right; gliding into a wall grabs it (Up/Down climb, A/B/C jumps off), touching the ground slides him to a stop with dust. Gliding and sliding attack badniks and break monitors; an enemy that takes several hits ends the glide. Springs, OOZ and WFZ fans, MTZ's triangle springs and wind tunnels end a glide or climb, and Wing Fortress Zone's ending is re-timed for his jump, as in KiS2. SST: `glide_mode` = `$23` (Sonic's `peelout_flag`) and `glide_property` = `$1F`; RAM `Gliding_collision_flags`, `Disable_wall_grab`. Light Dash uses his glide pose and turned running frames. In 1P games Knuckles plays KiS2's object layouts for the 18 acts it changed (invisible walls, path swappers, monitors and springs for his lower jump and his climbing; `level/objects/Knuckles/`, imported by the tool); `Knuckles_ObjectLayout` picks them in `ObjectsManager_Init`, other acts and characters keep Sonic 2's. KiS2 has no Grab, GlideLand or GroundSlide sounds; neither does this port. Around him (from KiS2, via the tool): his K.T.E life icon, Knuckles on the signpost and on the CNZ slot machine, KNUCKLES GOT THROUGH (its K goes over the M that only MILES uses), and the shield, the invincibility stars and their monitor icons in grey, since Sonic's blue is his red and green; the grey shield and stars are this project's art with KiS2's colour changes (`tools/nemesis.py`, from s1_improvements, recompresses the stars). In Special Stages Knuckles uses KiS2's sprites, mappings, DPLCs and palette (line 1; the bombs move to line 2 as in KiS2), the HUD drops the SONIC name, and the results say KNUCKLES GOT A CHAOS EMERALD with KiS2's layout and letters. Knuckles' frames are $37 tiles longer than Sonic's, so the player art buffer grows by that much (into `TempArray_LayerDef`, which only levels use): Sonic and Tails' frames are unpacked further on and Knuckles' over Sonic's, which keeps Tails' frames for Knuckles and Tails, whose results keep Sonic 2's MILES/TAILS RINGS line. On the Continue screen Knuckles shadow-boxes with his continue icons and runs off when you continue; Knuckles Alone has no Tails there, as in KiS2, Knuckles and Tails keeps him. The ending is KiS2's for Knuckles: one ending (`Ending_Routine` 0) with his palette (also in the ending's palette changer) and final picture (`objCF Knuckles.asm`), eagles with all the emeralds and Flickies otherwise; KiS2's own closing banner is not used. Code: `code/Knuckles.asm`. |
| Light Dash | Implemented | In the air, A next to a chain of at least three uncollected rings (64 pixels to the first, up to 72 between rings) dashes along it at 12 pixels per frame (6 under water), as in s1_improvements; without a chain A does the normal air move, and B/C never dash. Sonic and Tails Alone; the dash attacks badniks, follows curved chains and the ground, and leaves with the last link's direction. The targets are the rings manager's `Ring_Positions`, so no ring objects are involved. |
| Super Peel-Out | Implemented | Standing still, hold Up and press A/B/C to charge (100 per frame up to twice the top speed, at most $1000); let go of Up to launch an upright run at that speed, or cancel below $600. As in s1_improvements; Sonic 2 has no figure-eight frames or Peel-Out sounds, so the charge runs the normal run cycle on the spot with the Spin Dash sounds. Sonic only; the charge state uses SST `$23` (`peelout_flag`). |
| Victory poses | Implemented | After the signpost or the egg prison the player stays on screen: once landed the controls lock, he stops, the results start and Sonic shows the two-finger pose from AleDrawer2008's [Add Victory Poses In Sonic 1](https://info.sonicretro.org/SCHG_How-to:Add_Victory_Poses_In_Sonic_1), as in s1_improvements. `tools/import_victory_poses.py` makes frames $DB-$DC from s1_improvements' source bundle (`cd/Victory Sprites.png`); Sonic 2 keeps Sonic's colours at the same palette indices. While the clock is stopped the right level bound loses its $40 margin, so a player who keeps running stays on screen. In Tails Alone games Tails gives S3K's thumbs-up and kneels (`AniTails13`); `tools/import_tails_poses.py` imports those frames ($9C-$9D) and his Super transformation ($9E-$A0) from the S3K sprites in the same bundle, remapping S3K's colours to Sonic 2's player palette. His separate tails stay blank in these poses, whose frames use their tiles. 2P VS games keep the original ending. |
| Super Tails | Implemented | In Tails Alone games, as in s1_improvements: with seven emeralds (or ALL EMERALDS) and SUPER RINGS rings, A+B or B+C during a jump turns Tails Super and back (a flight started by the first button is cancelled; a combo never starts later in a flight). He plays S3K's transformation pose (frames $9E-$A0, with its white flash), keeps his sprites, his fur (colours 11, 15, 14) runs S3K's six-frame yellow cycle and he moves with S3K's Super values (top speed $800, acceleration $18, deceleration $C0, halved under water). Rings drain as for Super Sonic; no stars or Flickies. The underwater palette is not cycled yet. |
| Homing Attack and Jump Dash | Implemented | A, B or C in the air (once per jump; hitting a target allows another). Left/Right held at the press choose the direction. The Homing Attack takes the nearest badnik or intact monitor ahead within 150 pixels and aims at the upper third of its hitbox, as in s1_improvements; with no target Sonic dashes straight. Up + jump calls the Tails AI instead in Sonic and Tails games. |
| Tails flight and underwater swimming poses | Implemented | Jump again in the air. Press a jump button repeatedly to flap upwards; the timer gives eight seconds of powered flight. Water uses separate swimming poses. |
| Carry Sonic and fly assist | Implemented | The Tails AI can catch Sonic during a flight. While held, Left/Right steer, a fresh Up flaps, and a fresh jump lets Sonic go. |
| Shield DPLC | Implemented | The shield uses uncompressed tiles on demand. Both players have separate 12-tile slots. |
| Sonic CD spring twirl | Implemented | Five new frames are appended to Sonic's mappings so the existing animation frame IDs remain stable. |
| Music by act | Implemented | Act 2 has distinct EHZ, MCZ and CNZ tracks; all other zones keep the original track. |
| New title demos | Implemented | Two extra demos follow the original four: CPZ Act 1 shows the AI assist carrying Sonic, and CNZ Act 1 shows assisted flight. They are selected by demo slot, so the original CPZ and CNZ demos still play. |

Tails flies with A, B or C after an initial jump. Player 2 can fly directly
in versus play, or in Sonic and Tails mode while controlling Tails; otherwise
Player 1's Up plus another jump calls the AI assist. Carried Sonic uses a fresh
Up to flap and a fresh A/B/C input to detach.

Implementation guides used: [Tails flying and swimming](https://info.sonicretro.org/SCHG_How-to:Add_Tails'_flying_and_swimming_to_Sonic_2), [shield DPLCs](https://info.sonicretro.org/SCHG_How-to:Making_shields_use_DPLCs), [Sonic CD spring twirl](https://info.sonicretro.org/SCHG_How-to:Port_Sonic_CD's_spring_twirl_animation), [music per act](https://info.sonicretro.org/SCHG_How-to:Play_different_songs_per_act), and [custom demos](https://info.sonicretro.org/SCHG_How-to:Create_custom_demos).

The added Tails sprite poses come from the Tails guide's sprite sheet. The five Sonic CD spring poses came from [Sonic Research Community's twirl sprite archive](https://sonicresearch.org/community/index.php?attachments/twirlsprites-zip.11022/). Flight sound data was adapted from the [Sonic 3 disassembly SFX sources](https://github.com/sonicretro/skdisasm/tree/master/Sound/SFX).
