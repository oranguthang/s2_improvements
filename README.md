# s2_improvements

`s2_improvements` is a Sonic the Hedgehog 2 disassembly-based project focused on gameplay, engine, and quality-of-life improvements implemented from Sonic Retro tutorials.

This repository is built on top of the Sonic 2 community disassembly and gradually ports fixes and features from the Sonic Retro hacking guides into one project.

To build this project, use `build.bat` on Windows, or `build.lua` otherwise. The built ROM will be called `s2built.bin`. The Lua script requires Lua 5.3 or later.

See also:
- Sonic Retro Disassemblies: https://info.sonicretro.org/Disassemblies
- Sonic Retro How-To guides: https://info.sonicretro.org/SCHG_How-to:Guide

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

## Custom fixes

- Prevent Tails from losing rings in Special Stage during co-op

## Work in progress

- [Create a Homing Attack from scratch](https://info.sonicretro.org/SCHG_How-to:Create_a_Homing_Attack_from_scratch) is currently `WIP` and lives on the `homing_attack` branch for now.
- [Add Extended Camera to Sonic 1](https://info.sonicretro.org/SCHG_How-to:Add_Extended_Camera_to_Sonic_1) is currently `WIP` and lives on the `extended_camera` branch for now.

## Disclaimer

Any and all content presented in this repository is presented for informational and educational purposes only.
Commercial usage is expressly prohibited. Sonic Retro claims no ownership of any code in these repositories.
You assume any and all responsibility for using this content responsibly. Sonic Retro claims no responsibility or warranty.
