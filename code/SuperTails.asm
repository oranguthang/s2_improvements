; ---------------------------------------------------------------------------
; Super Tails (FeatureSuperTails), as in s1_improvements and Sonic 3 & Knuckles:
; in a Tails Alone game, with seven emeralds (or ALL EMERALDS) and enough rings
; (SUPER RINGS), A+B, A+C or B+C during a jump turns Tails Super; the same
; combo turns him back, also in flight. He keeps his normal sprites, plays S3K's transformation pose,
; and his fur cycles through S3K's yellow ramp. Super movement uses S3K's values
; for Tails (ApplySpeedSettings). No stars and no Flickies. Rings drain as for
; Super Sonic (RING DRAIN). It shares Super Sonic's state: Super_Sonic_flag,
; Super_Sonic_palette, Palette_timer/frame and Super_Sonic_frame_count.
; ---------------------------------------------------------------------------

; Z=0 only for the active Super Tails player.
SuperTails_Active:
	tst.b	(Super_Sonic_flag).w
	bne.s	SuperTails_Player
	rts

; Z=0 when a0 is Tails as the player of a 1P game (Tails Alone)
SuperTails_Player:
	cmpa.w	#MainCharacter,a0
	bne.s	.no
	cmpi.b	#ObjID_Tails,id(a0)
	bne.s	.no
	tst.w	(Two_player_mode).w
	bne.s	.no
	tst.w	(Demo_mode_flag).w
	bne.s	.no
	andi	#~4,ccr				; Z=0
	rts
.no:
	ori	#4,ccr				; Z=1
	rts

; ---------------------------------------------------------------------------
; Called from Tails_JumpHeight (and from his flight: a flight started by the
; first button of the combo is cancelled). Returns Z=0 if Tails transformed
; or reverted, so the caller skips the rest of the jump/flight handling.
; ---------------------------------------------------------------------------
Tails_ToggleSuper:
	if FeatureSuperTails=0
	ori	#4,ccr
	rts
	endif
	bsr.s	SuperTails_Player
	beq.w	.none
	tst.b	(Control_Locked).w		; cutscenes
	bne.w	.none
	; While the lock bit is set, wait until the jump buttons are released.
	btst	#7,(SuperTails_combo_buttons).w
	beq.s	.checkTimer
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
	bne.w	.none
	clr.w	(SuperTails_combo_timer).w	; and SuperTails_combo_buttons
	bra.w	.none
.checkTimer:
	tst.b	(SuperTails_combo_timer).w
	beq.s	.checkPress
	subq.b	#1,(SuperTails_combo_timer).w
	bne.s	.checkPress
	clr.b	(SuperTails_combo_buttons).w	; window expired
.checkPress:
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
	beq.w	.none
	tst.b	flying(a0)			; later in a flight a combo only
	beq.s	.accumulate			; turns Super Tails back
	tst.b	(Super_Sonic_flag).w
	bne.s	.accumulate
	tst.b	(SuperTails_combo_timer).w
	beq.w	.none
.accumulate:
	move.b	(SuperTails_combo_buttons).w,d1
	andi.b	#button_A_mask|button_B_mask|button_C_mask,d1
	or.b	d0,d1
	move.b	d1,(SuperTails_combo_buttons).w
	move.b	#super_combo_window,(SuperTails_combo_timer).w
	move.b	d1,d2
	andi.b	#button_A_mask|button_B_mask,d2
	cmpi.b	#button_A_mask|button_B_mask,d2
	beq.s	.combo
	move.b	d1,d2
	andi.b	#button_A_mask|button_C_mask,d2
	cmpi.b	#button_A_mask|button_C_mask,d2
	beq.s	.combo
	andi.b	#button_B_mask|button_C_mask,d1
	cmpi.b	#button_B_mask|button_C_mask,d1
	bne.w	.none
.combo:
	clr.b	(SuperTails_combo_timer).w
	move.b	#$80,(SuperTails_combo_buttons).w	; lock until released
	tst.b	(Super_Sonic_flag).w
	bne.w	Tails_RevertToNormal_Combo
	jsr	(HasAllEmeralds).l
	bne.w	.none
	moveq	#0,d0
	move.b	(Cheat_super_rings).w,d0
	cmp.w	(Ring_count).w,d0
	bhi.w	.none
	tst.b	(Update_HUD_timer).w		; the act is over
	beq.w	.none
	; Transform: the S3K pose holds him while the palette fades in.
	clr.b	flying(a0)			; the first button may have started a flight
	bclr	#status.player.rolling,status(a0)
	move.b	#$F,y_radius(a0)
	move.b	#9,x_radius(a0)
	move.b	#1,(Super_Sonic_palette).w
	jsr (SoloTails_BeginPalette).l
	move.b	#$F,(Palette_timer).w
	move.w	#0,(Palette_frame).w
	move.b	#1,(Super_Sonic_flag).w
	move.w	#60,(Super_Sonic_frame_count).w
	move.b	#$81,obj_control(a0)
	move.b	#AniIDTailsAni_Transform,anim(a0)
	move.w	#0,invincibility_time(a0)
	bset	#status_secondary.invincible,status_secondary(a0)
	jsr	(Super_DropSpeedShoes).l
	lea	(Tails_top_speed).w,a2
	jsr	(ApplySpeedSettings).l
	move.w	#SndID_SuperTransform,d0
	jsr	(PlaySound).l
	jsr	(Super_PlayMusic).l
.done:
	andi	#~4,ccr				; Z=0
	rts
.none:
	ori	#4,ccr				; Z=1
	rts

Tails_RevertToNormal_Combo:
	if FeatureSuperToggle=0
	ori	#4,ccr				; only the ring count ends it
	rts
	endif
	bsr.s	Tails_RevertToNormal
	andi	#~4,ccr				; Z=0
	rts

; ---------------------------------------------------------------------------
; Every frame for Tails (Obj02 control): ring drain and the end of the act.
; ---------------------------------------------------------------------------
Tails_Super:
	if FeatureSuperTails=0
	rts
	endif
	bsr.w	SuperTails_Active
	beq.s	.return
	cmpi.b	#1,(Super_Sonic_palette).w	; still transforming?
	beq.s	.return
	tst.b	(Update_HUD_timer).w
	beq.s	Tails_RevertToNormal
	subq.w	#1,(Super_Sonic_frame_count).w
	bhi.s	.return
	move.w	#60,(Super_Sonic_frame_count).w
	tst.b	(Cheat_ring_drain).w
	beq.s	.return
	tst.w	(Ring_count).w
	beq.s	Tails_RevertToNormal
	ori.b	#1,(Update_HUD_rings).w
	cmpi.w	#1,(Ring_count).w
	beq.s	+
	cmpi.w	#10,(Ring_count).w
	beq.s	+
	cmpi.w	#100,(Ring_count).w
	bne.s	++
+
	ori.b	#$80,(Update_HUD_rings).w
+
	subq.w	#1,(Ring_count).w
	beq.s	Tails_RevertToNormal
.return:
	rts

Tails_RevertToNormal:
	move.b	#0,obj_control(a0)
	jsr	(Super_RevertMusic).l
	move.b	#2,(Super_Sonic_palette).w	; fade the fur back
	move.w	#$28,(Palette_frame).w
	move.b	#0,(Super_Sonic_flag).w
	move.b	#AniIDSonAni_Run,prev_anim(a0)	; restart the animation
	move.w	#1,invincibility_time(a0)	; Obj02 ends the invincibility and resumes the music
	lea	(Tails_top_speed).w,a2
	jmp	(ApplySpeedSettings).l

; ---------------------------------------------------------------------------
; Turning back from Super: in a boss fight the boss's music plays again (the
; end of the invincibility, a frame later, leaves the music alone there).
; Elsewhere that end of invincibility plays the level's song. Used by Sonic,
; Knuckles and Tails.
; ---------------------------------------------------------------------------
Super_RevertMusic:
	jsr	(BossFightActive).l
	beq.s	.return
	move.w	#MusID_Boss,d0
	jmp	(PlayMusic_IfChanged).l
.return:
	rts

; End the form on the death frame, including when the air timer kills P1.
; Preserve the caller's killer/bubble pointer in a2.
Super_ResetOnDeath:
	cmpa.w	#MainCharacter,a0
	bne.s	.return
	tst.b	(Super_Sonic_flag).w
	bne.s	.reset
	tst.b	(Super_Sonic_palette).w
	beq.s	.return
.reset:
	movem.l	d0/a0-a2,-(sp)
	clr.b	(Super_Sonic_flag).w
	clr.w	(Super_Sonic_frame_count).w
	clr.b	obj_control(a0)
	bclr	#status_secondary.invincible,status_secondary(a0)
	clr.w	invincibility_time(a0)
	move.b	#-1,prev_anim(a0)
	move.b	#-1,(Sonic_LastLoadedDPLC).w
    if fixBugs
	lea	(Sonic_top_speed).w,a2
	cmpi.b	#ObjID_Tails,id(a0)
	bne.s	.speed
	lea	(Tails_top_speed).w,a2
.speed:
	jsr	(ApplySpeedSettings).l
    endif
	clr.w	(Palette_frame).w	; run the final restoration step immediately
	clr.b	(Palette_timer).w
	move.b	#2,(Super_Sonic_palette).w
	jsr	(PalCycle_SuperSonic).l
	cmpi.b	#MusID_SuperSonic,(Music_playing).w
	bne.s	.done
	move.w	(Level_Music).w,d0
	jsr	(BossFightActive).l
	beq.s	.music
	move.w	#MusID_Boss,d0
.music:
	jsr	(PlayMusic_IfChanged).l
.done:
	movem.l	(sp)+,d0/a0-a2
.return:
	rts

; ---------------------------------------------------------------------------
; Speed shoes do not work on a Super player (Sonic, Tails, Knuckles): turning
; Super ends them and their faster tempo, and the monitor gives him none
; (super_shoes). a0 = the player.
; ---------------------------------------------------------------------------
Super_DropSpeedShoes:
	bclr	#status_secondary.speed_shoes,status_secondary(a0)
	beq.s	.return
	clr.w	speedshoes_time(a0)
	move.w	#MusID_SlowDown,d0
	jmp	(PlayMusic).l
.return:
	rts

; ---------------------------------------------------------------------------
; The end of WFZ: the Tornado's jumps are timed for Sonic and Super Sonic, so
; Super Tails and Super Knuckles turn back before the cutscene (Super Tails
; would fly over the plane). a1 = the player.
; ---------------------------------------------------------------------------
Super_RevertForCutscene:
	tst.b	(Super_Sonic_flag).w
	beq.s	.return
	move.l	a0,-(sp)
	movea.l	a1,a0
	bsr.w	SuperTails_Player
	beq.s	.notTails
	bsr.w	Tails_RevertToNormal
	clr.b (Super_Sonic_palette).w
	jsr (SoloTails_EndPalette).l	; restore the pilot's blue before the plane arrives
	bra.s	.done
.notTails:
	tst.b	(Main_character).w
	beq.s	.done				; Super Sonic stays, as in the original
	jsr	(Sonic_RevertToNormal).l
.done:
	movea.l	a0,a1
	movea.l	(sp)+,a0
.return:
	rts

; ---------------------------------------------------------------------------
; Palette: called by PalCycle_SuperSonic when Tails is the player. Same states
; as Super Sonic's (1 = fade in, -1 = cycle, 2 = fade out); Tails' fur is in
; protected colours 4, 3 and 2 of the first palette line.
; ---------------------------------------------------------------------------
PalCycle_SuperTails:
	move.b	(Super_Sonic_palette).w,d0
	beq.w	.return
	bmi.w	.normal
	subq.b	#1,d0
	bne.w	.revert
	; fade in (S3K keeps his colours during the pose)
	subq.b	#1,(Palette_timer).w
	bpl.w	.return
	move.b	#3,(Palette_timer).w
	move.w	(Palette_frame).w,d0
	addq.w	#8,(Palette_frame).w
	cmpi.w	#$30,(Palette_frame).w
	blo.s	.copy
	move.b	#-1,(Super_Sonic_palette).w	; done
	move.b	#0,(MainCharacter+obj_control).w	; give Tails back his controls
	bra.s	.copy
.revert:
	subq.b	#1,(Palette_timer).w
	bpl.w	.return
	move.b	#3,(Palette_timer).w
	move.w	(Palette_frame).w,d0
	subq.w	#8,(Palette_frame).w
	bcc.s	.copy
	move.w	#0,(Palette_frame).w
	move.b	#0,(Super_Sonic_palette).w
	jmp (SoloTails_EndPalette).l
.normal:
	; S3K's Super Tails cycle: six frames of twelve game frames each
	subq.b	#1,(Palette_timer).w
	bpl.w	.return
	move.b	#11,(Palette_timer).w
	move.w	(Palette_frame).w,d0
	addq.w	#8,(Palette_frame).w
	cmpi.w	#$58,(Palette_frame).w
	bls.s	.copy
	move.w	#$30,(Palette_frame).w
.copy:
	lea	PalCycle_SuperTails_Colours(pc),a0
	lea	(Normal_palette).w,a1
	bsr.w SuperTails_CopyCycle
	if FeatureSuperTails
	tst.b	(Water_flag).w
	beq.s	.return
	; Use the zone's underwater table (tools/super_water.py). The pose
	; and reversion keep the zone's normal Tails ramp.
	lea	PalCycle_SuperTails_CPZ(pc),a0
	cmpi.b	#chemical_plant_zone,(Current_Zone).w
	beq.s	.water
	lea	PalCycle_SuperTails_HPZ(pc),a0
	cmpi.b	#hidden_palace_zone,(Current_Zone).w
	beq.s	.water
	lea	PalCycle_SuperTails_ARZ(pc),a0
.water:
	lea	(Underwater_palette).w,a1
	bsr.w SuperTails_CopyCycle
	endif
.return:
	rts

; colours 11, 15, 14 (and a pad word) per frame, from S3K's Super Tails cycle
; (s1_improvements' palette/Cycle - Super Tails.bin): six frames of normal
; colours for the pose, then the six-frame yellow cycle
PalCycle_SuperTails_Colours:
	rept 6
	dc.w	$046A, $008E, $00AE, 0
	endm
	dc.w	$046A, $008E, $00AE, 0
	dc.w	$046A, $02AE, $04CE, 0
	dc.w	$046C, $04CE, $08CE, 0
	dc.w	$048E, $08CE, $0AEE, 0
	dc.w	$046C, $04CE, $08CE, 0
	dc.w	$046A, $02AE, $04CE, 0
	if FeatureSuperTails
; underwater frames (tools/super_water.py)
PalCycle_SuperTails_CPZ:	BINCLUDE	"art/palettes/Super Tails CPZ underwater.bin"
PalCycle_SuperTails_ARZ:	BINCLUDE	"art/palettes/Super Tails ARZ underwater.bin"
PalCycle_SuperTails_HPZ:	BINCLUDE	"art/palettes/Super Tails HPZ underwater.bin"
	endif

; Start a Super theme only when enabled; the current boss, level and 1-up
; playback stays untouched when the user has disabled it.
Super_PlayMusic:
	tst.b	(Cheat_super_music).w
	bne.s	.theme
	cmpi.b	#MusID_Invincible,(Music_playing).w
	bne.s	.return
	move.w	(Level_Music).w,d0
	jsr	(BossFightActive).l
	beq.s	.restore
	move.w	#MusID_Boss,d0
.restore:
	jmp	(PlayMusic_IfChanged).l
.theme:
	move.w	#MusID_SuperSonic,d0
	jmp	(PlayMusic).l
.return:
	rts

; Only Super gameplay uses the remapped sheet. Normal Tails, the ending,
; co-op and VS retain their original art and palette layout.
SoloTails_SelectArt:
	if FeatureSuperTails
	cmpi.w #PlayerMode_TailsAlone,(Player_mode).w
	bne.s .return
	tst.w (Two_player_mode).w
	bne.s .return
	tst.b (Super_Sonic_palette).w
	beq.s .return
	cmpi.b #GameModeID_Level,(Game_Mode).w
	beq.s .level
	cmpi.b #GameModeID_Level+$80,(Game_Mode).w
	bne.s .return
.level:
	move.l #ArtUnc_SoloTails,d6
	lea (MapRUnc_SoloTails).l,a2
	endif
.return:
	rts

SoloTails_BeginPalette:
	movem.l a1,-(sp)
	lea (Normal_palette).w,a1
	bsr.s .copy
	lea (Underwater_palette).w,a1
	bsr.s .copy
	bsr.w SoloTails_LoadLifePortrait
	bra.s SoloTails_RefreshArt
.copy:
	move.w 11*2(a1),4*2(a1)
	move.w 15*2(a1),3*2(a1)
	move.w 14*2(a1),2*2(a1)
	rts

SoloTails_EndPalette:
	movem.l a1,-(sp)
	cmpi.b #GameModeID_EndingSequence,(Game_Mode).w
	beq.s SoloTails_RefreshArt
	move.l (Target_palette+4).w,(Normal_palette+4).w
	move.w (Target_palette+8).w,(Normal_palette+8).w
	move.l (Underwater_target_palette+4).w,(Underwater_palette+4).w
	move.w (Underwater_target_palette+8).w,(Underwater_palette+8).w
	bsr.s SoloTails_LoadLifePortrait
	move.b #-1,(Tails_LastLoadedDPLC).w
	move.b #-1,(TailsTails_LastLoadedDPLC).w
	; PalCycle runs after objects. Queue the original pixels in this same
	; frame as restoring blue, so the last fade frame cannot flash blue.
	movem.l d0-d6/a0-a2,-(sp)
	lea (MainCharacter).w,a0
	jsr (LoadTailsDynPLC).l
	lea (Tails_Tails).w,a0
	jsr (LoadTailsTailsDynPLC).l
	movem.l (sp)+,d0-d6/a0-a2
	movem.l (sp)+,a1
	rts
SoloTails_RefreshArt:
	move.b #-1,(Tails_LastLoadedDPLC).w
	move.b #-1,(TailsTails_LastLoadedDPLC).w
	movem.l (sp)+,a1
	rts

; Switch only the four life portrait tiles when switching fur palettes.
SoloTails_LoadLifePortrait:
	cmpi.b #GameModeID_Level,(Game_Mode).w
	beq.s .level
	cmpi.b #GameModeID_Level+$80,(Game_Mode).w
	bne.s .return
.level:
	movem.l d0-d3/a1,-(sp)
	move.l #ArtUnc_SoloTailsLifePortraits,d1
	tst.b (Super_Sonic_palette).w
	beq.s .queue
	addi.l #tiles_to_bytes(4),d1
.queue:
	move.w #tiles_to_bytes(ArtTile_ArtNem_life_counter),d2
	move.w #tiles_to_words(4),d3
	jsr (QueueDMATransfer).l
	movem.l (sp)+,d0-d3/a1
.return:
	rts

; a0/d0 = cycle entry, a1 = palette. Levels use protected player colours.
; The ending has a Sonic pilot and no enemies: keep its original layout.
SuperTails_CopyCycle:
	cmpi.b #GameModeID_EndingSequence,(Game_Mode).w
	beq.s .ending
	move.w (a0,d0.w),4*2(a1)
	move.w 2(a0,d0.w),3*2(a1)
	move.w 4(a0,d0.w),2*2(a1)
	rts
.ending:
	move.w (a0,d0.w),11*2(a1)
	move.w 2(a0,d0.w),15*2(a1)
	move.w 4(a0,d0.w),14*2(a1)
	rts

; SCZ's Sonic pilot needs his own blue pixels while Super Tails owns the
; first line's blue slots. SCZ uses neither sky colours 14/15 of line 2 nor
; colour 15 of line 3. Two fur layers use those spare entries; his face,
; red shoes and light-blue highlight stay on the original first line.
SoloTails_PreparePilot:
	if FeatureSuperTails
	cmpi.w #PlayerMode_TailsAlone,(Player_mode).w
	bne.w .return
	cmpi.b #sky_chase_zone,(Current_Zone).w
	bne.w .return
	cmpi.b #GameModeID_Level,(Game_Mode).w
	bne.w .return
	cmpi.l #Map_SoloSonicPilot,mappings(a0)
	beq.s .mapped
	move.l #Map_SoloSonicPilot,mappings(a0)
	clr.b objoff_37(a0)       ; load all layers on the first mapped frame
.mapped:
	movem.l a1,-(sp)
	lea (Normal_palette+4).w,a1
	tst.b (Super_Sonic_palette).w
	beq.s .blue
	lea (Target_palette+4).w,a1
.blue:
	move.w (a1),(Normal_palette+$5C).w
	move.w 2(a1),(Normal_palette+$5E).w
	move.w 4(a1),(Normal_palette+$7E).w
	move.w (Target_palette+4).w,(Target_palette+$5C).w
	move.w (Target_palette+6).w,(Target_palette+$5E).w
	move.w (Target_palette+8).w,(Target_palette+$7E).w
	movem.l (sp)+,a1
	endif
.return:
	rts

SoloTails_LoadPilot:
	if FeatureSuperTails
	cmpi.w #PlayerMode_TailsAlone,(Player_mode).w
	bne.s .original
	cmpi.b #sky_chase_zone,(Current_Zone).w
	bne.s .original
	cmpi.b #GameModeID_Level,(Game_Mode).w
	bne.s .original
	subi.b #$2D,d0
	cmp.b (Sonic_LastLoadedDPLC).w,d0
	beq.s .return
	move.b d0,(Sonic_LastLoadedDPLC).w
	lea (MapRUnc_SoloSonicPilot).l,a2
	move.l #ArtUnc_SoloSonicPilot,d6
	move.w #tiles_to_bytes(ArtTile_ArtUnc_Sonic),d4
	jmp (LoadDynPLC).l
	endif
.original:
	jmp (LoadSonicDynPLC_Part2).l
.return:
	rts
