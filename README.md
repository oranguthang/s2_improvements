# s2_improvements

`s2_improvements` is a Sonic the Hedgehog 2 disassembly-based project focused on gameplay, engine, and quality-of-life improvements implemented from Sonic Retro tutorials.

This repository is built on top of the Sonic 2 community disassembly and gradually ports fixes and features from the Sonic Retro hacking guides into one project.

To build this project, use `build.bat` on Windows, or `build.lua` otherwise. The built ROM will be called `s2built.bin`. The Lua script requires Lua 5.3 or later.

See also:
- Sonic Retro Disassemblies: https://info.sonicretro.org/Disassemblies
- Sonic Retro How-To guides: https://info.sonicretro.org/SCHG_How-to:Guide

## Upstream migration and ROM compatibility

This branch ports the improvements from `master` at `bfadfbd` onto Sonic Retro
upstream `380f37a`. The roll-jump collision-height fix from `a2f70eb` is already
provided by upstream; the other 37 commits have been replayed with conflicts
resolved.

The default `preserveLegacyROM = 1` in `s2.compatibility.asm` retains the original
ROM output with `gameRevision = 2`, `fixBugs = 1`, and `padToPowerOfTwo = 0`.
It keeps the original implementations of newly changed upstream collision,
boss, background, sprite-priority, and debug-list behavior, plus music modulation
conversion. The newer upstream implementations remain available by setting
`preserveLegacyROM = 0`; that mode intentionally produces a different ROM.
The existing project improvements and earlier bug fixes remain enabled in both
modes. Music assembly shares this setting, and the build script invalidates the
generated music cache when it changes.

The reference ROM built from `master` at `bfadfbd` is 1,081,322 bytes and has MD5
`ca1f52e9cb999f5fa92d665d3eb508a4`.

After building, compare against the saved reference ROM using the bundled Lua:

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
| Configure VS countdown | Planned | All three start triggers, HUD, music and expiry |
| Improve character Debug mode | Planned | Tails Alone, movement reset, cameras, water, HUD and Level Select |
| Preserve level state after Special Stage | Planned | Rings, object consumption and shields for both players; ordinary deaths and new levels |

Hidden Palace from the official 2013 remake is a later project, outside this batch.
The pre-improvement ROM remains the migration reference; new features intentionally
change ROM bytes. The compatibility switch still controls only the newer upstream
changes described above.

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

## Custom fixes

- Prevent Tails from losing rings in Special Stage during co-op

## Disclaimer

Any and all content presented in this repository is presented for informational and educational purposes only.
Commercial usage is expressly prohibited. Sonic Retro claims no ownership of any code in these repositories.
You assume any and all responsibility for using this content responsibly. Sonic Retro claims no responsibility or warranty.
