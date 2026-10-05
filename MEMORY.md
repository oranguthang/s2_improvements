# Memory map of the mod's additions

What the project's features use on top of the Sonic 2 disassembly, and what is
still free. Addresses are 68000 RAM (`$FFFFxxxx`, written as `$xxxx`). Check
`s2.lst` for the current values after changing `s2.constants.asm`.

## Player object fields (SST)

Fields `$20`, `$21` and `$23` are free in stock player objects, so each
character uses them for its own moves. Shared code that reads them must first
check which object it is looking at (as `Touch_Enemy` does with
`cmpi.b #ObjID_Tails,id(a0)` before `flying(a0)`).

| Offset | Sonic (Obj01) | Tails (Obj02) | Notes |
|---|---|---|---|
| `$20` | `transform_combo_timer` | `flying` | The Knuckles tutorial puts `gliding_mode` here |
| `$21` | `transform_combo_buttons` | `flying_timer` | The Knuckles tutorial puts `gliding_property` here |
| `$23` | — | `carry_delay` | |
| `$1F` | — | — | Free, but cleared by `loc_A53A` and `ObjB2_Landed_on_plane` |
| `status` bit 4 | homing attack used this jump | — | Was the roll-jump lock bit, removed by the Roll-Jump Lock tutorial |
| `status_secondary` bit 3 | being carried by Tails (`status_secondary.carry`) | — | |

Do not use the "Free up 2 universal SSTs" or S3K priority manager tutorials as
written: they move `inertia` to `$20/$21`.

Other objects:

| Object | Field | Use |
|---|---|---|
| Scattered rings (Obj37) | `lostrings_timer` = `objoff_1F` | Per-ring deletion timer (Fix Ring Timers) |
| Tails' tails (Obj05) | `Obj05_parent_prev_anim` = `objoff_30` | Subanimation fix |
| Shield (Obj38) | `objoff_30`, `objoff_32` | Last DPLC frame and VRAM destination (separate slots for both players) |

## RAM variables added by the mod

| Address | Name | Feature |
|---|---|---|
| `$EEEA` | `Camera_pan` (word) | Extended camera |
| `$F100-$F5FF` | `Sprite_Table_Alternate`, `Sprite_Table_P2_Alternate` | Double-buffered sprite tables (`fixBugs`); this is where the Sonic 1 driver / Clone Driver tutorial wants its RAM |
| `$F608-$F60B` | `Ctrl_1_Held_6B`, `Ctrl_1_Press_6B`, `Ctrl_2_Held_6B`, `Ctrl_2_Press_6B` | Six-button controllers |
| `$F7C0-$F7C3` | `Sidekick_X_vel_copy`, `Sidekick_Y_vel_copy` | Tails carrying Sonic |
| `$F7D8` | `Water_Ripple_Phase` (word) | LZ water ripple |
| `$FA80-$FA81` | `Current_sprite_table_page`, `Sprite_table_page_flip_pending` | Sprite table double buffering (`fixBugs`) |
| `$FE2A-$FE2E` | `SS_keep_level_state`, `SS_saved_shield(_2P)`, `SS_saved_extra_life_flags(_2P)` | Level state after a Special Stage |
| `$FEDA-$FEDF` | `SS_saved_rings(_2P)`, `SS_saved_zone` | Level state after a Special Stage |
| `$FF44-$FF47` | `SS_saved_perfect_rings`, `SS_saved_perfect_flag` | Level state after a Special Stage |
| `$FF76` | `VS_countdown_option` (word) | VS finish countdown option |
| `$FF87` | `Level_select_page` | Level Select pages |

The Special Stage snapshot itself needs no buffer: the object respawn table
and the ring consumption table are simply not cleared while the Special Stage
runs.

## Free RAM in levels

| Address | Size | Notes |
|---|---|---|
| `$D400-$D5FF` | 512 | Between the level-only objects and the collision index |
| `$E740-$E7FF` | 192 | Before `Ring_Positions` |
| `$FA82-$FAFF` | 126 | After the sprite table page bytes |
| `$DF80-$DFFF` | 128 | Only if the sprite table can never overflow into it |
| `$FEB0-$FEBF`, `$FEFA-$FF0F`, `$FF12-$FF1F`, `$FF60-$FF6F` | 16, 22, 14, 16 | Persistent area (not cleared on level start) |
| `$F79A-$F7A6`, `$F7B4-$F7BD`, `$F676-$F67F` | 13, 10, 10 | |

Plus about 60 single bytes and small gaps marked "seems unused" in
`s2.constants.asm`. `$86DC` and `$DBA8` are only free in the Special Stage
RAM layout. The S3K rings manager tutorial would free most of
`Ring_Positions` (`$1F0` bytes with 511 rings), but needs two-player support
first.

## Z80 sound driver

The build prints how many bytes are left before the music buffer at `$1380`
(currently `$118`). Each new song takes 4 playlist bytes and 1 tempo byte.
